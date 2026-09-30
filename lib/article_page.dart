import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'news_api.dart';
import 'theme.dart';
import 'widgets.dart';

// ======================================================
// TELA DE LEITURA DA NOTÍCIA
// ======================================================

class ArticlePage extends StatelessWidget {
  final NewsArticle article;

  const ArticlePage({super.key, required this.article});

  // Muitos feeds trazem só o começo da matéria; o texto completo fica no site.
  // Abre o site dentro do app (navegador embutido do Android); se o aparelho
  // não suportar, cai para o navegador externo.
  Future<void> openOriginal(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = safeWebUri(article.url);
    if (url == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Link da matéria inválido.')),
      );
      return;
    }

    var opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    }

    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a matéria.')),
      );
    }
  }

  // Evita repetir o resumo quando o conteúdo já começa com ele.
  bool get showSummary {
    String clean(String text) =>
        text.replaceAll('…', '').replaceAll(RegExp(r'\s+'), ' ').trim();

    final summary = clean(article.summary);
    return summary.isNotEmpty && !clean(article.content).startsWith(summary);
  }

  // Tempo estimado de leitura do texto disponível (~200 palavras por minuto).
  String get readingTime {
    final words = '${article.summary} ${article.content}'
        .split(RegExp(r'\s+'))
        .length;
    final minutes = (words / 200).ceil().clamp(1, 60);
    return '$minutes min de leitura';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconButton(
                tooltip: 'Voltar',
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.30),
                ),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            actions: [
              BookmarkButton(article: article, onImage: true),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: NewsImage(article: article, iconSize: 64),
            ),
          ),

          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TopicPill(category: article.category),

                      const SizedBox(height: 14),

                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 27,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                colors.primary.withValues(alpha: 0.14),
                            child: Text(
                              article.source.substring(0, 1),
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.source,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${article.time} · $readingTime',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      if (showSummary) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(18),
                            border: Border(
                              left: BorderSide(
                                color: colors.primary,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Text(
                            article.summary,
                            style: const TextStyle(
                              fontSize: 16.5,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      Text(
                        article.content,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.7,
                          color: colors.onSurface.withValues(alpha: 0.85),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Quer continuar lendo?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'O texto acima é o trecho enviado pelo ${article.source}. '
                              'A matéria completa abre aqui mesmo, no app.',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: () => openOriginal(context),
                              icon: const Icon(Icons.chrome_reader_mode_outlined),
                              label: const Text('Ler matéria completa'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
