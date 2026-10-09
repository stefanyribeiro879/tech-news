import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'motion.dart';
import 'news_api.dart';
import 'theme.dart';
import 'widgets.dart';

// ======================================================
// TELA FEED
// Rolagem contínua: as notícias mais recentes, uma após a outra. Quando o
// usuário chega perto do fim, a próxima página é buscada sozinha. Puxar a
// lista para baixo atualiza. Os chips filtram por tema (favoritos primeiro).
// ======================================================

const int feedPageSize = 15;

class FeedPage extends StatefulWidget {
  final List<String> favorites;

  const FeedPage({super.key, required this.favorites});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final scrollController = ScrollController();

  String? category; // null = todas
  final List<NewsArticle> items = [];
  final Set<String> _ids = {}; // evita repetir notícia entre páginas

  int page = 0; // última página carregada
  bool hasMore = true;
  bool loading = true; // primeira página
  bool reloading = false; // primeira página sendo buscada de novo
  bool loadingMore = false;
  String? error; // erro na primeira página
  String? moreError; // erro ao carregar mais
  int _request = 0; // descarta respostas antigas ao trocar de tema

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    reload();
  }

  @override
  void didUpdateWidget(FeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o tema escolhido saiu dos favoritos, volta para "Todas".
    // Espera o frame terminar: aqui ainda estamos no meio do build e não é
    // hora de mexer na rolagem.
    if (!listEquals(oldWidget.favorites, widget.favorites) &&
        category != null &&
        !widget.favorites.contains(category)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) chooseCategory(null);
      });
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      loadMore();
    }
  }

  // Se a primeira página não enche a tela (ex.: monitor grande), o usuário
  // não conseguiria rolar: busca a próxima sem esperar.
  void _fillScreenIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      if (scrollController.position.maxScrollExtent <= 0) {
        loadMore();
      }
    });
  }

  void chooseCategory(String? value) {
    if (value == category) return;
    setState(() {
      category = value;
      // Tira as notícias do tema anterior: assim aparece o "carregando" e
      // não misturamos páginas de temas diferentes.
      items.clear();
      _ids.clear();
      page = 0;
      hasMore = true;
    });
    if (scrollController.hasClients) scrollController.jumpTo(0);
    reload();
  }

  // Volta para a primeira página (abertura, troca de tema e puxar para baixo).
  Future<void> reload() async {
    final request = ++_request;
    reloading = true;

    setState(() {
      loading = items.isEmpty; // com lista na tela, o indicador é o do puxar
      loadingMore = false; // um "carregar mais" pendente será descartado
      error = null;
      moreError = null;
    });

    try {
      final result = await NewsApi.page(
        category: category,
        page: 1,
        limit: feedPageSize,
      );
      if (!mounted || request != _request) return;

      setState(() {
        items
          ..clear()
          ..addAll(result.items);
        _ids
          ..clear()
          ..addAll(result.items.map((a) => a.id));
        page = 1;
        hasMore = result.hasMore;
        reloading = false;
        loading = false;
        loadingMore = false;
      });
      _fillScreenIfNeeded();
    } catch (e) {
      if (!mounted || request != _request) return;
      final keepList = items.isNotEmpty;
      setState(() {
        // Se já havia notícias na tela, elas continuam lá: só avisamos.
        if (!keepList) error = e.toString();
        reloading = false;
        loading = false;
        loadingMore = false;
      });
      if (keepList) {
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Não foi possível atualizar o feed agora.'),
            ),
          );
      }
    }
  }

  Future<void> loadMore() async {
    // Enquanto a primeira página é buscada de novo, o número da página atual
    // não vale mais: espera ela chegar.
    if (loading || reloading || loadingMore || !hasMore || error != null) {
      return;
    }

    final request = _request;
    setState(() {
      loadingMore = true;
      moreError = null;
    });

    try {
      final result = await NewsApi.page(
        category: category,
        page: page + 1,
        limit: feedPageSize,
      );
      if (!mounted || request != _request) return;

      setState(() {
        // O cache do servidor se renova a cada 15 min e pode deslocar as
        // páginas: ignora o que já está na tela.
        for (final article in result.items) {
          if (_ids.add(article.id)) items.add(article);
        }
        page = result.page;
        hasMore = result.hasMore && result.items.isNotEmpty;
        loadingMore = false;
      });
      _fillScreenIfNeeded();
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        moreError = e.toString();
        loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final margins = pagePadding(context, top: 16);

    // Só as margens laterais: o espaço de cima e de baixo vai nos blocos.
    Widget block(Widget child) => SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: margins.left),
          sliver: SliverToBoxAdapter(child: child),
        );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: reload,
        // CustomScrollView + SliverList: só os cartões que aparecem na tela
        // são montados, mesmo com centenas de notícias carregadas.
        child: CustomScrollView(
          controller: scrollController,
          // Permite puxar para atualizar mesmo com pouca coisa na tela.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            block(
              Padding(
                padding: EdgeInsets.only(top: margins.top),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feed',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tudo que acabou de sair, sem parar de rolar.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    _FeedFilters(
                      favorites: widget.favorites,
                      selected: category,
                      onSelect: chooseCategory,
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            if (loading)
              block(const LoadingState(message: 'Carregando o feed...'))
            else if (error != null)
              block(
                EmptyState(
                  emoji: '📡',
                  title: 'Não conseguimos carregar o feed',
                  subtitle: error!,
                  actionLabel: 'Tentar novamente',
                  onAction: reload,
                ),
              )
            else if (items.isEmpty)
              block(
                const EmptyState(
                  emoji: '🗞️',
                  title: 'Nada por aqui ainda',
                  subtitle: 'Ainda não há notícias desse tema. Puxe para '
                      'baixo para atualizar ou escolha outro tema.',
                ),
              )
            else ...[
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: margins.left),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FeedCard(
                      key: ValueKey(items[index].id),
                      article: items[index],
                    ),
                    childCount: items.length,
                    // Mantém o scroll certo se a lista mudar (ids estáveis).
                    findChildIndexCallback: (key) {
                      final id = (key as ValueKey<String>).value;
                      final index = items.indexWhere((a) => a.id == id);
                      return index < 0 ? null : index;
                    },
                  ),
                ),
              ),
              block(
                _FeedFooter(
                  loadingMore: loadingMore,
                  hasMore: hasMore,
                  error: moreError,
                  onRetry: loadMore,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: margins.bottom)),
            ],
          ],
        ),
      ),
    );
  }
}

// ======================================================
// FILTROS (chips de tema)
// ======================================================

class _FeedFilters extends StatelessWidget {
  final List<String> favorites;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _FeedFilters({
    required this.favorites,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final others = topics
        .map((topic) => topic.category)
        .where((category) => !favorites.contains(category));

    Widget chip(String label, IconData icon, bool isSelected, VoidCallback tap) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => tap(),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(
            'Todas',
            Icons.dynamic_feed_rounded,
            selected == null,
            () => onSelect(null),
          ),
          for (final category in [...favorites, ...others])
            chip(
              category,
              topicOf(category).icon,
              selected == category,
              () => onSelect(selected == category ? null : category),
            ),
        ],
      ),
    );
  }
}

// ======================================================
// RODAPÉ DA LISTA (carregando, erro ou fim)
// ======================================================

class _FeedFooter extends StatelessWidget {
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  final VoidCallback onRetry;

  const _FeedFooter({
    required this.loadingMore,
    required this.hasMore,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              'Não foi possível carregar mais notícias.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    }

    if (loadingMore || hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Você viu tudo por agora. 🎉',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ======================================================
// CARTÃO DO FEED (imagem em cima, texto embaixo)
// ======================================================

class FeedCard extends StatelessWidget {
  final NewsArticle article;

  const FeedCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Pressable(
        child: Material(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openArticle(context, article),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NewsImage(article: article, iconSize: 48),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: BookmarkButton(article: article, onImage: true),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TopicPill(category: article.category),
                      const SizedBox(height: 10),
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (article.summary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          article.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${article.source} · ${article.time}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ReadMoreButton(article: article),
                        ],
                      ),
                    ],
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
