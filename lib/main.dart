import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'news_api.dart';

void main() {
  runApp(const TechNewsApp());
}

// ======================================================
// CORES DO APP
// ======================================================

const Color appBackground = Color(0xFF090B10);
const Color cardBackground = Color(0xFF131620);
const Color purple = Color(0xFF604BFF);
const Color lightPurple = Color(0xFF9C8CFF);

// ======================================================
// APLICATIVO
// ======================================================

class TechNewsApp extends StatelessWidget {
  const TechNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tech News',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: appBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.dark,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF10131A),
          indicatorColor: purple,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}

// ======================================================
// CONTROLE PRINCIPAL DO APP
// ======================================================

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedPage = 0;

  // Guarda a notícia inteira, pois ela pode sair da lista da API depois.
  final Map<String, NewsArticle> savedArticles = {};

  void changePage(int index) {
    setState(() {
      selectedPage = index;
    });
  }

  void toggleSaved(NewsArticle article) {
    setState(() {
      if (savedArticles.containsKey(article.id)) {
        savedArticles.remove(article.id);
      } else {
        savedArticles[article.id] = article;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        savedArticles: savedArticles,
        onToggleSaved: toggleSaved,
        onOpenExplore: () => changePage(1),
      ),
      ExplorePage(
        savedArticles: savedArticles,
        onToggleSaved: toggleSaved,
      ),
      SavedPage(
        savedArticles: savedArticles,
        onToggleSaved: toggleSaved,
      ),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedPage,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        onDestinationSelected: changePage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Salvos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ======================================================
// TELA INICIAL
// ======================================================

class HomePage extends StatefulWidget {
  final Map<String, NewsArticle> savedArticles;
  final Function(NewsArticle) onToggleSaved;
  final VoidCallback onOpenExplore;

  const HomePage({
    super.key,
    required this.savedArticles,
    required this.onToggleSaved,
    required this.onOpenExplore,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'Destaques';

  // Os nomes precisam ser iguais às categorias do backend.
  final List<String> categories = const [
    'Destaques',
    'Inteligência Artificial',
    'Mobile',
    'Games',
    'Segurança',
    'Geral',
  ];

  List<NewsArticle> news = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  Future<void> loadNews() async {
    final category = selectedCategory;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await NewsApi.latest(
        category: category == 'Destaques' ? null : category,
      );

      // Ignora a resposta se o usuário já trocou de categoria.
      if (!mounted || category != selectedCategory) return;

      setState(() {
        news = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted || category != selectedCategory) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void selectCategory(String category) {
    if (category == selectedCategory) return;

    setState(() {
      selectedCategory = category;
    });
    loadNews();
  }

  @override
  Widget build(BuildContext context) {
    // O destaque é a notícia mais recente que tem imagem.
    final featured = news.isEmpty
        ? null
        : news.firstWhere(
            (article) => article.imageUrl != null,
            orElse: () => news.first,
          );
    final latest = news.where((article) => article != featured);

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: RefreshIndicator(
              onRefresh: loadNews,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                children: [
                  const Text(
                    'Olá! 👋',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'O que está acontecendo\nno mundo da tecnologia?',
                    style: TextStyle(
                      fontSize: 27,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final selected =
                            selectedCategory == category;

                        return GestureDetector(
                          onTap: () => selectCategory(category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? purple
                                  : cardBackground,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Carregando notícias...\n'
                            'Na primeira vez pode levar até 1 minuto.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  else if (error != null)
                    EmptyMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Erro ao carregar notícias',
                      subtitle: error!,
                      actionLabel: 'Tentar novamente',
                      onAction: loadNews,
                    )
                  else if (featured == null)
                    const EmptyMessage(
                      icon: Icons.article_outlined,
                      title: 'Nenhuma notícia encontrada',
                      subtitle:
                          'Ainda não temos notícias nessa categoria.',
                    )
                  else ...[
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Em destaque',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onOpenExplore,
                          child: const Text(
                            'Ver tudo',
                            style: TextStyle(
                              color: lightPurple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    FeaturedCard(
                      article: featured,
                      isSaved:
                          widget.savedArticles.containsKey(featured.id),
                      onToggleSaved: () {
                        widget.onToggleSaved(featured);
                      },
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Últimas notícias',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ...latest.map(
                      (article) => NewsListCard(
                        article: article,
                        isSaved:
                            widget.savedArticles.containsKey(article.id),
                        onToggleSaved: () {
                          widget.onToggleSaved(article);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 5),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'TECH NEWS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),

          IconButton(
            onPressed: widget.onOpenExplore,
            icon: const Icon(Icons.search_rounded),
          ),

          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Você não possui novas notificações.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// CARD PRINCIPAL
// ======================================================

class FeaturedCard extends StatelessWidget {
  final NewsArticle article;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  const FeaturedCard({
    super.key,
    required this.article,
    required this.isSaved,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openArticle(
          context,
          article,
          isSaved,
          onToggleSaved,
        );
      },
      child: Container(
        height: 245,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkNewsImage(
              url: article.imageUrl,
            ),

            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(30, 0, 0, 0),
                    Color.fromARGB(230, 5, 5, 15),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: purple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const Spacer(),

                      IconButton.filledTonal(
                        onPressed: onToggleSaved,
                        icon: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    article.time,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// CARD DE NOTÍCIA
// ======================================================

class NewsListCard extends StatelessWidget {
  final NewsArticle article;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  const NewsListCard({
    super.key,
    required this.article,
    required this.isSaved,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        openArticle(
          context,
          article,
          isSaved,
          onToggleSaved,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF20232D),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 82,
              height: 82,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: NetworkNewsImage(
                  url: article.imageUrl,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category.toUpperCase(),
                    style: const TextStyle(
                      color: lightPurple,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    article.time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: onToggleSaved,
              icon: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isSaved
                    ? lightPurple
                    : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// TELA EXPLORAR
// ======================================================

class ExplorePage extends StatefulWidget {
  final Map<String, NewsArticle> savedArticles;
  final Function(NewsArticle) onToggleSaved;

  const ExplorePage({
    super.key,
    required this.savedArticles,
    required this.onToggleSaved,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String search = '';
  List<NewsArticle> results = [];
  bool loading = true;
  String? error;

  // Espera o usuário parar de digitar antes de chamar a API.
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  void onSearchChanged(String value) {
    search = value.trim();
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), loadResults);
  }

  // Sem texto (ou com só 1 letra), mostra as notícias mais recentes.
  Future<void> loadResults() async {
    final query = search;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = query.length < 2
          ? await NewsApi.latest(limit: 50)
          : await NewsApi.search(query);

      // Ignora a resposta se o texto da busca já mudou.
      if (!mounted || query != search) return;

      setState(() {
        results = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted || query != search) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Explorar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Pesquisar notícias...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? EmptyMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Erro ao carregar notícias',
                    subtitle: error!,
                    actionLabel: 'Tentar novamente',
                    onAction: loadResults,
                  )
                : results.isEmpty
                ? const EmptyMessage(
                    icon: Icons.search_off_rounded,
                    title: 'Nada encontrado',
                    subtitle:
                        'Tente pesquisar usando outra palavra.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      5,
                      20,
                      30,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final article = results[index];

                      return NewsListCard(
                        article: article,
                        isSaved: widget.savedArticles
                            .containsKey(article.id),
                        onToggleSaved: () {
                          widget.onToggleSaved(article);
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// TELA SALVOS
// ======================================================

class SavedPage extends StatelessWidget {
  final Map<String, NewsArticle> savedArticles;
  final Function(NewsArticle) onToggleSaved;

  const SavedPage({
    super.key,
    required this.savedArticles,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    final saved = savedArticles.values.toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'Notícias salvas',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          Expanded(
            child: saved.isEmpty
                ? const EmptyMessage(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Nenhuma notícia salva',
                    subtitle:
                        'Toque no ícone de favorito para guardar uma notícia aqui.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      5,
                      20,
                      30,
                    ),
                    itemCount: saved.length,
                    itemBuilder: (context, index) {
                      final article = saved[index];

                      return NewsListCard(
                        article: article,
                        isSaved: true,
                        onToggleSaved: () {
                          onToggleSaved(article);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// PERFIL
// ======================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Perfil',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 30),

          Center(
            child: Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'TECH NEWS',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 6),

          const Center(
            child: Text(
              'Tecnologia em um só lugar.',
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
          ),

          const SizedBox(height: 35),

          const ProfileOption(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            subtitle: 'Gerencie seus alertas',
          ),

          const ProfileOption(
            icon: Icons.category_outlined,
            title: 'Categorias favoritas',
            subtitle: 'Escolha os assuntos que mais gosta',
          ),

          const ProfileOption(
            icon: Icons.dark_mode_outlined,
            title: 'Aparência',
            subtitle: 'Tema escuro ativado',
          ),

          const ProfileOption(
            icon: Icons.info_outline_rounded,
            title: 'Sobre o TECH NEWS',
            subtitle: 'Versão 1.0.0',
          ),
        ],
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: lightPurple,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white38,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
      ),
    );
  }
}

// ======================================================
// TELA COMPLETA DA NOTÍCIA
// ======================================================

class ArticlePage extends StatefulWidget {
  final NewsArticle article;
  final bool initiallySaved;
  final VoidCallback onToggleSaved;

  const ArticlePage({
    super.key,
    required this.article,
    required this.initiallySaved,
    required this.onToggleSaved,
  });

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  late bool saved;

  @override
  void initState() {
    super.initState();
    saved = widget.initiallySaved;
  }

  // Muitos feeds trazem só o começo da matéria; o texto completo fica no site.
  Future<void> openOriginal() async {
    final opened = await launchUrl(
      Uri.parse(widget.article.url),
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a matéria.'),
        ),
      );
    }
  }

  // Evita repetir o resumo quando o conteúdo já começa com ele.
  bool get showSummary {
    String clean(String text) =>
        text.replaceAll('…', '').replaceAll(RegExp(r'\s+'), ' ').trim();

    final summary = clean(widget.article.summary);
    return summary.isNotEmpty &&
        !clean(widget.article.content).startsWith(summary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: appBackground,
            actions: [
              IconButton(
                onPressed: () {
                  widget.onToggleSaved();

                  setState(() {
                    saved = !saved;
                  });
                },
                icon: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Compartilhamento será adicionado em breve.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkNewsImage(
                    url: widget.article.imageUrl,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromARGB(25, 0, 0, 0),
                          Color.fromARGB(230, 9, 11, 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.category.toUpperCase(),
                    style: const TextStyle(
                      color: lightPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      fontSize: 29,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  if (showSummary) ...[
                    const SizedBox(height: 15),

                    Text(
                      widget.article.summary,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.45,
                        color: Colors.white70,
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: purple,
                        child: Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.article.source,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.article.time,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Divider(
                    color: Color(0xFF272A34),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    widget.article.content,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.7,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: openOriginal,
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(
                        'Ler matéria completa no ${widget.article.source}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// FUNÇÃO PARA ABRIR UMA NOTÍCIA
// ======================================================

void openArticle(
  BuildContext context,
  NewsArticle article,
  bool isSaved,
  VoidCallback onToggleSaved,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ArticlePage(
        article: article,
        initiallySaved: isSaved,
        onToggleSaved: onToggleSaved,
      ),
    ),
  );
}

// ======================================================
// IMAGENS
// ======================================================

class NetworkNewsImage extends StatelessWidget {
  final String? url;

  const NetworkNewsImage({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return _placeholder();
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      // Na versão web, usa <img> quando o site da imagem bloqueia o acesso (CORS).
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: cardBackground,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      },
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: cardBackground,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: lightPurple,
        size: 40,
      ),
    );
  }
}

// ======================================================
// MENSAGEM DE LISTA VAZIA
// ======================================================

class EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 65,
              color: lightPurple,
            ),

            const SizedBox(height: 18),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                height: 1.4,
              ),
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),

              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}