import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ======================================================
// ENDEREÇO DA API
// ======================================================

// Backend publicado no Render. Confira o endereço exato no painel do Render
// (se o nome já existir, ele acrescenta um sufixo, ex.: technews-a3-api-x1y2).
const String productionApiUrl = 'https://technews-a3-api.onrender.com';

// Pode ser trocado ao rodar o app:
// flutter run --dart-define=API_URL=http://192.168.0.10:8000
const String _apiUrlFromEnv = String.fromEnvironment('API_URL');

String get apiBaseUrl {
  if (_apiUrlFromEnv.isNotEmpty) {
    return _apiUrlFromEnv;
  }

  // Versão publicada (flutter build) usa o servidor online.
  if (kReleaseMode) {
    return productionApiUrl;
  }

  // No emulador Android, 10.0.2.2 aponta para o computador.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }

  return 'http://127.0.0.1:8000';
}

// ======================================================
// LINKS SEGUROS
// Links e imagens vêm de feeds de terceiros: só aceitamos http(s).
// Bloqueia "javascript:", "data:", "file:" etc.
// ======================================================

Uri? safeWebUri(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  if (uri == null || uri.host.isEmpty) return null;
  return (uri.scheme == 'https' || uri.scheme == 'http') ? uri : null;
}

// ======================================================
// MODELO DA NOTÍCIA
// ======================================================

class NewsArticle {
  final String id;
  final String category;
  final String title;
  final String summary;
  final String content;
  final String source;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;

  const NewsArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.content,
    required this.source,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
      source: json['source'] as String,
      url: json['url'] as String,
      // Imagem com endereço estranho é ignorada (mostra o ícone do tema).
      imageUrl: safeWebUri(json['image_url'] as String?)?.toString(),
      publishedAt: DateTime.parse(json['published_at'] as String).toLocal(),
    );
  }

  // Linha da tabela saved_articles do Supabase (mesmos campos, id em article_id).
  factory NewsArticle.fromSavedRow(Map<String, dynamic> row) {
    return NewsArticle.fromJson({...row, 'id': row['article_id']});
  }

  Map<String, dynamic> toSavedRow() {
    return {
      'article_id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'url': url,
      'image_url': imageUrl,
      'source': source,
      'category': category,
      'published_at': publishedAt.toUtc().toIso8601String(),
    };
  }

  // Texto como "Há 20 minutos", "Ontem" ou "12/09/2026".
  String get time {
    final diff = DateTime.now().difference(publishedAt);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) {
      return diff.inMinutes == 1
          ? 'Há 1 minuto'
          : 'Há ${diff.inMinutes} minutos';
    }
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? 'Há 1 hora' : 'Há ${diff.inHours} horas';
    }
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';

    final day = publishedAt.day.toString().padLeft(2, '0');
    final month = publishedAt.month.toString().padLeft(2, '0');
    return '$day/$month/${publishedAt.year}';
  }
}

// ======================================================
// CHAMADAS À API
// ======================================================

// Uma página de notícias, com o total para saber se ainda há mais.
class NewsPageResult {
  final List<NewsArticle> items;
  final int total;
  final int page;
  final int limit;

  const NewsPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  bool get hasMore => page * limit < total;
}

class NewsApiException implements Exception {
  final String message;

  const NewsApiException(this.message);

  @override
  String toString() => message;
}

class NewsApi {
  // No plano gratuito do Render o servidor "dorme" e leva até ~1 min para acordar.
  static const Duration _timeout = Duration(seconds: 90);

  // Pode ser trocado nos testes por um cliente falso (package:http/testing).
  static http.Client client = http.Client();

  static Future<List<NewsArticle>> latest({
    String? category,
    int limit = 30,
  }) async {
    final data = await _get('/news', {
      'category': ?category, // só envia se não for null
      'limit': '$limit',
    });
    return _articles(data['items']);
  }

  // Uma página do feed (rolagem contínua). O backend limita `limit` a 50.
  static Future<NewsPageResult> page({
    String? category,
    int page = 1,
    int limit = 15,
  }) async {
    final data = await _get('/news', {
      'category': ?category,
      'page': '$page',
      'limit': '$limit',
    });
    return NewsPageResult(
      items: _articles(data['items']),
      total: (data['total'] as num?)?.toInt() ?? 0,
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
    );
  }

  static Future<List<NewsArticle>> search(String query) async {
    final data = await _get('/news/search', {'q': query, 'limit': '50'});
    return _articles(data['items']);
  }

  static List<NewsArticle> _articles(dynamic items) {
    return (items as List)
        .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);

    final http.Response response;
    try {
      response = await client.get(uri).timeout(_timeout);
    } catch (_) {
      throw NewsApiException(
        'Não foi possível conectar ao servidor ($apiBaseUrl). '
        'Verifique se o backend está rodando.',
      );
    }

    if (response.statusCode != 200) {
      throw NewsApiException(
        'O servidor respondeu com erro ${response.statusCode}.',
      );
    }

    // utf8.decode garante que os acentos cheguem corretos.
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
