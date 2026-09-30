import 'package:flutter/material.dart';

import 'saved_articles.dart';
import 'theme.dart';
import 'widgets.dart';

// ======================================================
// TELA SALVOS
// Lista as notícias guardadas na conta (tabela saved_articles).
// ======================================================

class SavedPage extends StatelessWidget {
  final VoidCallback onGoHome;

  const SavedPage({super.key, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: savedArticles,
        builder: (context, _) {
          final saved = savedArticles.items;

          return ListView(
            padding: pagePadding(context, top: 16),
            children: [
              const Text(
                'Seus salvos',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                saved.isEmpty
                    ? 'Guarde notícias para ler com calma depois.'
                    : saved.length == 1
                    ? '1 notícia guardada para ler com calma.'
                    : '${saved.length} notícias guardadas para ler com calma.',
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              if (saved.isEmpty)
                EmptyState(
                  emoji: '🔖',
                  title: 'Nenhuma notícia salva ainda',
                  subtitle:
                      'Toque no marcador de qualquer notícia para guardá-la aqui. '
                      'Elas ficam na sua conta, em qualquer aparelho.',
                  actionLabel: 'Ver notícias',
                  onAction: onGoHome,
                )
              else
                PagedNewsList(articles: saved),
            ],
          );
        },
      ),
    );
  }
}
