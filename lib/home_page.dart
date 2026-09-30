import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'logo.dart';
import 'motion.dart';
import 'news_api.dart';
import 'supabase_service.dart';
import 'theme.dart';
import 'widgets.dart';

// ======================================================
// TELA INICIAL
// Os temas favoritos do usuário ficam em foco: "Para você" mostra só eles,
// com um carrossel de destaques e uma seção para cada tema.
// ======================================================

const String forYouKey = 'Para você';
const String allKey = 'Todas';

class HomePage extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onOpenExplore;
  final VoidCallback onOpenProfile;
  final ValueChanged<String> onAddFavorite;

  const HomePage({
    super.key,
    required this.profile,
    required this.onOpenExplore,
    required this.onOpenProfile,
    required this.onAddFavorite,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selected = forYouKey;

  // "Para você": notícias de cada tema favorito.
  Map<String, List<NewsArticle>> byTopic = {};
  // Um tema específico ou "Todas".
  List<NewsArticle> list = [];

  bool loading = true;
  String? error;
  int _request = 0; // descarta respostas antigas ao trocar de aba rápido

  List<String> get favorites => widget.profile.favoriteCategories;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Temas mudaram no Perfil: recarrega o "Para você" depois deste build.
    final changed =
        !listEquals(oldWidget.profile.favoriteCategories, favorites);
    if (changed && selected == forYouKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) load();
      });
    }
  }

  void select(String key) {
    if (key == selected) return;
    setState(() {
      selected = key;
    });
    load();
  }

  Future<void> load() async {
    final request = ++_request;
    final key = selected;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (key == forYouKey) {
        final topicsToLoad = List<String>.from(favorites);
        final results = await Future.wait(
          topicsToLoad.map((c) => NewsApi.latest(category: c, limit: 12)),
        );
        if (!mounted || request != _request) return;

        setState(() {
          byTopic = {
            for (var i = 0; i < topicsToLoad.length; i++)
              topicsToLoad[i]: results[i],
          };
          loading = false;
        });
      } else {
        final result = await NewsApi.latest(
          category: key == allKey ? null : key,
          limit: 30,
        );
        if (!mounted || request != _request) return;

        setState(() {
          list = result;
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // Destaques alternando entre os temas favoritos (todos com imagem).
  List<NewsArticle> get highlights {
    final picks = <NewsArticle>[];
    for (var round = 0; round < 3 && picks.length < 6; round++) {
      for (final category in favorites) {
        final withImage = (byTopic[category] ?? const <NewsArticle>[])
            .where((article) => article.imageUrl != null)
            .toList();
        if (withImage.length > round && picks.length < 6) {
          picks.add(withImage[round]);
        }
      }
    }
    return picks;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context, top: 16),
          children: [
            _Greeting(
              profile: widget.profile,
              onSearch: widget.onOpenExplore,
              onProfile: widget.onOpenProfile,
            ),

            const SizedBox(height: 20),

            _TopicTabs(
              favorites: favorites,
              selected: selected,
              onSelect: select,
            ),

            const SizedBox(height: 22),

            if (loading)
              const LoadingState()
            else if (error != null)
              EmptyState(
                emoji: '📡',
                title: 'Não conseguimos buscar as notícias',
                subtitle: error!,
                actionLabel: 'Tentar novamente',
                onAction: load,
              )
            else if (selected == forYouKey)
              ..._buildForYou(context)
            else
              ..._buildTopicList(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildForYou(BuildContext context) {
    final featured = highlights;
    final featuredIds = featured.map((article) => article.id).toSet();

    if (byTopic.values.every((items) => items.isEmpty)) {
      return [
        const EmptyState(
          emoji: '🗞️',
          title: 'Nada novo nos seus temas agora',
          subtitle: 'Puxe para atualizar daqui a pouco ou veja "Todas".',
        ),
      ];
    }

    return [
      if (featured.isNotEmpty) ...[
        const SectionHeader(title: 'Destaques para você'),
        Appear(child: _HighlightsCarousel(articles: featured)),
        const SizedBox(height: 28),
      ],

      for (final category in favorites)
        ..._topicSection(category, featuredIds),
    ];
  }

  // Seção de um tema favorito (sem repetir o que já está nos destaques).
  List<Widget> _topicSection(String category, Set<String> featuredIds) {
    final items = (byTopic[category] ?? const <NewsArticle>[])
        .where((article) => !featuredIds.contains(article.id))
        .toList();
    if (items.isEmpty) return const [];

    return [
      SectionHeader(
        title: category,
        topic: topicOf(category),
        actionLabel: 'Ver tudo',
        onAction: () => select(category),
      ),
      PagedNewsList(articles: items),
      const SizedBox(height: 22),
    ];
  }

  List<Widget> _buildTopicList(BuildContext context) {
    final isAll = selected == allKey;
    final topic = isAll ? null : topicOf(selected);
    final isFavorite = favorites.contains(selected);

    if (list.isEmpty) {
      return [
        const EmptyState(
          emoji: '🗞️',
          title: 'Nenhuma notícia por aqui',
          subtitle: 'Ainda não chegou nada desse tema. Tente mais tarde.',
        ),
      ];
    }

    final featured = list.firstWhere(
      (article) => article.imageUrl != null,
      orElse: () => list.first,
    );

    return [
      SectionHeader(
        title: isAll ? 'Todas as notícias' : selected,
        topic: topic,
      ),

      // Sugere adicionar aos favoritos quem está vendo um tema que não segue.
      if (!isAll && !isFavorite)
        _AddFavoriteTip(
          topic: topic!,
          onAdd: () => widget.onAddFavorite(selected),
        ),

      Appear(
        child: SizedBox(height: 250, child: FeaturedNewsCard(article: featured)),
      ),

      const SizedBox(height: 22),

      PagedNewsList(
        articles: list.where((article) => article != featured).toList(),
      ),
    ];
  }
}

// ======================================================
// SAUDAÇÃO
// ======================================================

class _Greeting extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onSearch;
  final VoidCallback onProfile;

  const _Greeting({
    required this.profile,
    required this.onSearch,
    required this.onProfile,
  });

  String get _partOfDay {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _topicsSummary {
    final names = profile.favoriteCategories
        .map((c) => c == 'Inteligência Artificial' ? 'IA' : c)
        .toList();
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Topo: logo à esquerda, busca e perfil à direita.
    // Abaixo: a saudação numa linha só ("Boa tarde, Levi").
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TechNewsLogo(height: 36),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Buscar',
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onProfile,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colors.primary,
                child: Text(
                  profile.initial,
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$_partOfDay, ',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: profile.firstName),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Separamos as novidades de $_topicsSummary para você.',
          style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
        ),
      ],
    );
  }
}

// ======================================================
// ABAS DE TEMAS
// Ordem: Para você → favoritos → Todas → demais temas.
// ======================================================

class _TopicTabs extends StatelessWidget {
  final List<String> favorites;
  final String selected;
  final ValueChanged<String> onSelect;

  const _TopicTabs({
    required this.favorites,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final others = topics
        .map((topic) => topic.category)
        .where((category) => !favorites.contains(category));

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Tab(
            label: forYouKey,
            icon: Icons.auto_awesome_rounded,
            selected: selected == forYouKey,
            onTap: () => onSelect(forYouKey),
          ),
          for (final category in favorites)
            _Tab(
              label: category,
              icon: topicOf(category).icon,
              topic: topicOf(category),
              selected: selected == category,
              onTap: () => onSelect(category),
            ),
          Container(
            width: 1,
            margin: const EdgeInsets.fromLTRB(2, 10, 10, 10),
            color: context.colors.outlineVariant,
          ),
          _Tab(
            label: allKey,
            icon: Icons.grid_view_rounded,
            selected: selected == allKey,
            muted: true,
            onTap: () => onSelect(allKey),
          ),
          for (final category in others)
            _Tab(
              label: category,
              icon: topicOf(category).icon,
              selected: selected == category,
              muted: true,
              onTap: () => onSelect(category),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Topic? topic;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.topic,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = topic?.foreground(context) ?? colors.primary;

    final Color background;
    final Color foreground;
    if (selected) {
      background = colors.primary;
      foreground = colors.onPrimary;
    } else if (muted) {
      background = Colors.transparent;
      foreground = colors.onSurfaceVariant;
    } else {
      background = topic?.background(context) ??
          colors.primary.withValues(alpha: 0.12);
      foreground = accent;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: background,
        shape: StadiumBorder(
          side: BorderSide(
            color: muted && !selected
                ? colors.outlineVariant
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
// CARROSSEL DE DESTAQUES
// ======================================================

class _HighlightsCarousel extends StatefulWidget {
  final List<NewsArticle> articles;

  const _HighlightsCarousel({required this.articles});

  @override
  State<_HighlightsCarousel> createState() => _HighlightsCarouselState();
}

class _HighlightsCarouselState extends State<_HighlightsCarousel> {
  final controller = PageController(viewportFraction: 0.92);
  int page = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        SizedBox(
          height: 270,
          child: PageView.builder(
            controller: controller,
            padEnds: false,
            itemCount: widget.articles.length,
            onPageChanged: (value) => setState(() => page = value),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FeaturedNewsCard(article: widget.articles[index]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.articles.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == page ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == page ? colors.primary : colors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ======================================================
// DICA: ADICIONAR TEMA AOS FAVORITOS
// ======================================================

class _AddFavoriteTip extends StatelessWidget {
  final Topic topic;
  final VoidCallback onAdd;

  const _AddFavoriteTip({required this.topic, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: topic.background(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Curtiu ${topic.category}? Adicione aos seus temas para ver em "Para você".',
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Adicionar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
