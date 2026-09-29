import 'package:flutter/foundation.dart';

import 'news_api.dart';
import 'supabase_service.dart';

// ======================================================
// NOTÍCIAS SALVAS
// Mantém uma cópia local (para a tela responder na hora) sincronizada com a
// tabela saved_articles do Supabase. Avisa as telas quando algo muda.
// ======================================================

class SavedArticlesStore extends ChangeNotifier {
  // Mais recentes primeiro.
  final List<NewsArticle> _items = [];

  List<NewsArticle> get items => List.unmodifiable(_items);

  bool contains(String id) => _items.any((article) => article.id == id);

  // Muda a cada alteração local, para descartar leituras que ficaram velhas.
  int _version = 0;

  Future<void> load() async {
    final version = _version;
    final articles = await SupabaseService.loadSaved();
    if (version != _version) return;

    _items
      ..clear()
      ..addAll(articles);
    notifyListeners();
  }

  void clear() {
    _version++;
    _items.clear();
    notifyListeners();
  }

  // Atualiza a tela antes e desfaz se o Supabase der erro.
  Future<void> toggle(NewsArticle article) async {
    _version++;
    final index = _items.indexWhere((item) => item.id == article.id);
    final wasSaved = index >= 0;

    if (wasSaved) {
      _items.removeAt(index);
    } else {
      _items.insert(0, article);
    }
    notifyListeners();

    try {
      if (wasSaved) {
        await SupabaseService.unsave(article.id);
      } else {
        await SupabaseService.save(article);
      }
    } catch (_) {
      if (wasSaved) {
        _items.insert(index, article);
      } else {
        _items.removeWhere((item) => item.id == article.id);
      }
      notifyListeners();
      rethrow;
    }
  }
}

final savedArticles = SavedArticlesStore();
