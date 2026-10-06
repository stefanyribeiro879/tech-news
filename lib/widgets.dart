import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'article_page.dart';
import 'motion.dart';
import 'news_api.dart';
import 'saved_articles.dart';
import 'theme.dart';

// ======================================================
// MARGENS DAS TELAS
// No celular, 20px; em telas largas (web), centraliza numa coluna de 760px.
// ======================================================

EdgeInsets pagePadding(
  BuildContext context, {
  double top = 8,
  double bottom = 30,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = width > 800 ? (width - 760) / 2 : 20.0;
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}

// ======================================================
// ABRIR NOTÍCIA E SALVAR
// ======================================================

void openArticle(BuildContext context, NewsArticle article) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ArticlePage(article: article)),
  );
}

Future<void> toggleSavedArticle(
  BuildContext context,
  NewsArticle article,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final wasSaved = savedArticles.contains(article.id);

  try {
    await savedArticles.toggle(article);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? 'Removida dos salvos.' : 'Guardada nos seus salvos. 🔖',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Não foi possível atualizar seus salvos.'),
      ),
    );
  }
}

// Ícone de salvar que se atualiza sozinho em qualquer tela.
class BookmarkButton extends StatelessWidget {
  final NewsArticle article;
  final bool onImage;

  const BookmarkButton({
    super.key,
    required this.article,
    this.onImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: savedArticles,
      builder: (context, _) {
        final saved = savedArticles.contains(article.id);
        final colors = context.colors;

        final icon = Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: onImage
              ? Colors.white
              : saved
              ? colors.primary
              : colors.onSurfaceVariant,
        );

        return IconButton(
          tooltip: saved ? 'Remover dos salvos' : 'Salvar',
          onPressed: () => toggleSavedArticle(context, article),
          style: onImage
              ? IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.30),
                )
              : null,
          icon: icon,
        );
      },
    );
  }
}

// ======================================================
// IMAGEM DA NOTÍCIA
// Sem imagem (ou com erro), mostra o ícone do tema num fundo colorido.
// ======================================================

class NewsImage extends StatelessWidget {
  final NewsArticle article;
  final double iconSize;

  const NewsImage({super.key, required this.article, this.iconSize = 36});

  @override
  Widget build(BuildContext context) {
    final url = article.imageUrl;
    if (url == null) return _placeholder(context);

    return Image.network(
      url,
      fit: BoxFit.cover,
      // Decodifica no tamanho de tela, não a foto inteira (que pode ter
      // milhares de pixels): economiza memória e evita travadas ao rolar.
      cacheWidth: 900,
      // Na versão web, usa <img> quando o site da imagem bloqueia o acesso (CORS).
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(context, loading: true),
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context, {bool loading = false}) {
    final topic = topicOf(article.category);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            topic.tint(context).withValues(alpha: 0.30),
            topic.tint(context).withValues(alpha: 0.10),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: loading
          ? null
          : Icon(topic.icon, size: iconSize, color: topic.foreground(context)),
    );
  }
}

// ======================================================
// PÍLULA DO TEMA
// ======================================================

class TopicPill extends StatelessWidget {
  final String category;
  final bool onImage;

  const TopicPill({super.key, required this.category, this.onImage = false});

  @override
  Widget build(BuildContext context) {
    final topic = topicOf(category);
    // Sobre a foto: fundo na cor do tema (branco no preto e branco).
    final onImageText = context.palette.monochrome
        ? Colors.black
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onImage ? topic.tint(context) : topic.background(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            topic.icon,
            size: 13,
            color: onImage ? onImageText : topic.foreground(context),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              topic.shortName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: onImage ? onImageText : topic.foreground(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// CARTÃO GRANDE (DESTAQUE)
// ======================================================

class FeaturedNewsCard extends StatelessWidget {
  final NewsArticle article;

  const FeaturedNewsCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: Material(
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openArticle(context, article),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NewsImage(article: article, iconSize: 56),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.25, 1],
                  colors: [Color(0x00000000), Color(0xDD120F18)],
                ),
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: BookmarkButton(article: article, onImage: true),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TopicPill(category: article.category, onImage: true),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${article.source} · ${article.time}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ReadMoreButton(article: article, onImage: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ======================================================
// CARTÃO COMPACTO (LISTAS HORIZONTAIS)
// ======================================================

class CompactNewsCard extends StatelessWidget {
  final NewsArticle article;

  const CompactNewsCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 230,
      child: Pressable(
      child: Material(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openArticle(context, article),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: NewsImage(article: article),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${article.source} · ${article.time}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          BookmarkButton(article: article),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// ======================================================
// LINHA DE NOTÍCIA (LISTAS VERTICAIS)
// ======================================================

class NewsListTile extends StatelessWidget {
  final NewsArticle article;

  const NewsListTile({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
      child: Material(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openArticle(context, article),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: NewsImage(article: article, iconSize: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TopicPill(category: article.category),
                      const SizedBox(height: 7),
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${article.source} · ${article.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ReadMoreButton(article: article),
                      ),
                    ],
                  ),
                ),
                BookmarkButton(article: article),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// ======================================================
// BOTÃO "LER MAIS"
// Abre a notícia dentro do app (ArticlePage).
// ======================================================

class ReadMoreButton extends StatelessWidget {
  final NewsArticle article;
  final bool onImage;

  const ReadMoreButton({
    super.key,
    required this.article,
    this.onImage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (onImage) {
      return FilledButton.icon(
        onPressed: () => openArticle(context, article),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        label: const Text('Ler mais'),
      );
    }

    return TextButton.icon(
      onPressed: () => openArticle(context, article),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
        foregroundColor: context.colors.primary,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      label: const Text('Ler mais'),
    );
  }
}

// ======================================================
// LISTA PAGINADA
// Mostra poucas notícias por vez (padrão: 3) com botões de página,
// em vez de uma rolagem sem fim.
// ======================================================

class PagedNewsList extends StatefulWidget {
  final List<NewsArticle> articles;
  final int perPage;

  const PagedNewsList({super.key, required this.articles, this.perPage = 3});

  @override
  State<PagedNewsList> createState() => _PagedNewsListState();
}

class _PagedNewsListState extends State<PagedNewsList> {
  final topKey = GlobalKey();
  int page = 0;
  bool forward = true;

  int get pageCount => (widget.articles.length / widget.perPage).ceil();

  @override
  void didUpdateWidget(PagedNewsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Lista nova (outro tema, busca, atualização): volta para a página 1.
    final sameList = listEquals(
      oldWidget.articles.map((a) => a.id).toList(),
      widget.articles.map((a) => a.id).toList(),
    );
    if (!sameList || page >= pageCount) page = 0;
  }

  void goTo(int next) {
    if (next == page || next < 0 || next >= pageCount) return;
    setState(() {
      forward = next > page;
      page = next;
    });

    // Traz o começo da lista para a tela, se a pessoa rolou para baixo.
    final target = topKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: motionDuration(context),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.articles
        .skip(page * widget.perPage)
        .take(widget.perPage)
        .toList();
    final slide = context.motion == MotionLevel.simple ? 0.0 : 0.08;

    return Column(
      key: topKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: motionDuration(context),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          // A página nova entra pelo lado para onde a pessoa avançou.
          transitionBuilder: (child, animation) {
            final incoming = child.key == ValueKey(page);
            final dx = incoming == forward ? slide : -slide;
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(dx, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Column(
            key: ValueKey(page),
            children: [
              for (var i = 0; i < items.length; i++)
                Appear(index: i, child: NewsListTile(article: items[i])),
            ],
          ),
        ),
        if (pageCount > 1)
          _Pager(page: page, pageCount: pageCount, onChanged: goTo),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  const _Pager({
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });

  // Números visíveis: primeira, última e as vizinhas da atual (null = "…").
  List<int?> get visiblePages {
    final pages = <int?>[];
    for (var i = 0; i < pageCount; i++) {
      final near = (i - page).abs() <= 1;
      if (i == 0 || i == pageCount - 1 || near) {
        pages.add(i);
      } else if (pages.isNotEmpty && pages.last != null) {
        pages.add(null);
      }
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            tooltip: 'Anteriores',
            onPressed: page > 0 ? () => onChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 6),
          for (final number in visiblePages)
            if (number == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '…',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _PageDot(
                  number: number + 1,
                  selected: number == page,
                  onTap: () => onChanged(number),
                ),
              ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            tooltip: 'Próximas',
            onPressed: page < pageCount - 1 ? () => onChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  final int number;
  final bool selected;
  final VoidCallback onTap;

  const _PageDot({
    required this.number,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Página $number',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: motionDuration(context, base: 200),
          width: selected ? 40 : 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// TÍTULO DE SEÇÃO
// ======================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final Topic? topic;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.topic,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final topic = this.topic;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (topic != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: topic.background(context),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                topic.icon,
                size: 19,
                color: topic.foreground(context),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

// ======================================================
// ESTADO VAZIO / ERRO
// ======================================================

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Carregamento com mensagem amigável.
class LoadingState extends StatelessWidget {
  final String message;

  const LoadingState({
    super.key,
    this.message = 'Buscando as últimas notícias...',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '$message\nNa primeira vez pode levar até 1 minuto.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
