import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ======================================================
// ENDEREÇO DA API
// ======================================================

// Backend publicado no Render. Confira o endereço exato no painel do Render
// (se o nome já existir, ele acrescenta um sufixo, ex.: tech-news-api-x1y2).
const String productionApiUrl = 'https://tech-news-api.onrender.com';

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
      imageUrl: json['image_url'] as String?,
      publishedAt: DateTime.parse(json['published_at'] as String).toLocal(),
    );
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

class NewsApiException implements Exception {
  final String message;

  const NewsApiException(this.message);

  @override
  String toString() => message;
}

class NewsApi {
  // No plano gratuito do Render o servidor "dorme" e leva até ~1 min para acordar.
  static const Duration _timeout = Duration(seconds: 90);

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
      response = await http.get(uri).timeout(_timeout);
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
