// Desenha as telas em tamanho de celular e de computador para garantir que
// nada "estoura" o layout (as faixas amarelas e pretas do Flutter).
// Rodar com: flutter test

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tech_news/appearance_page.dart';
import 'package:tech_news/article_page.dart';
import 'package:tech_news/favorite_topics_page.dart';
import 'package:tech_news/feed_page.dart';
import 'package:tech_news/home_page.dart';
import 'package:tech_news/login_page.dart';
import 'package:tech_news/logo.dart';
import 'package:tech_news/news_api.dart';
import 'package:tech_news/profile_page.dart';
import 'package:tech_news/saved_page.dart';
import 'package:tech_news/splash_screen.dart';
import 'package:tech_news/supabase_service.dart';
import 'package:tech_news/theme.dart';
import 'package:tech_news/widgets.dart';

// Tema sem Google Fonts (os testes não acessam a internet).
ThemeData testTheme(AppLook look) {
  final theme = buildTheme(look);
  return theme.copyWith(
    textTheme: ThemeData(brightness: look.brightness).textTheme,
  );
}

final article = NewsArticle(
  id: 'abc123',
  category: 'Inteligência Artificial',
  title: 'Um título de notícia bem comprido para testar como o texto quebra '
      'em várias linhas dentro dos cartões do aplicativo',
  summary: 'Resumo da notícia com algumas palavras.',
  content: 'Conteúdo da notícia.\n\nSegundo parágrafo do conteúdo.',
  source: 'g1 Tecnologia',
  url: 'https://example.com/noticia',
  imageUrl: null,
  publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
);

const profile = UserProfile(
  name: 'Maria Eduarda Silva',
  email: 'maria.eduarda@exemplo.com.br',
  favoriteCategories: ['Inteligência Artificial', 'Mobile', 'Segurança'],
);

const sizes = {
  'celular pequeno': Size(360, 740),
  'computador': Size(1280, 800),
};

Future<void> pumpScreen(
  WidgetTester tester,
  Size size,
  AppLook look,
  Widget screen,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: testTheme(look), home: screen),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final screens = <String, Widget Function()>{
    'cadastro/login': () => const AuthFlow(),
    'temas (primeiro acesso)': () => FavoriteTopicsPage(
          initial: const ['Mobile'],
          isOnboarding: true,
          firstName: 'Maria',
          onSaved: (_) {},
        ),
    'início (sem internet)': () => Scaffold(
          body: HomePage(
            profile: profile,
            onOpenExplore: () {},
            onOpenProfile: () {},
            onAddFavorite: (_) {},
          ),
        ),
    'feed': () => Scaffold(
          body: FeedPage(favorites: profile.favoriteCategories),
        ),
    'cartão do feed': () => Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [FeedCard(article: article)],
          ),
        ),
    'abertura': () => SplashScreen(onFinished: () {}),
    'salvos (vazio)': () => Scaffold(body: SavedPage(onGoHome: () {})),
    'perfil': () => Scaffold(
          body: ProfilePage(
            profile: profile,
            onEditTopics: () {},
            onLogout: () {},
          ),
        ),
    'notícia': () => ArticlePage(article: article),
    'aparência': () => const AppearancePage(),
    'lista paginada': () => Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PagedNewsList(articles: List.filled(8, article)),
            ],
          ),
        ),
    'cartões': () => Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SizedBox(height: 250, child: FeaturedNewsCard(article: article)),
              const SizedBox(height: 12),
              SizedBox(height: 258, child: CompactNewsCard(article: article)),
              const SizedBox(height: 12),
              NewsListTile(article: article),
              const SectionHeader(
                title: 'Inteligência Artificial',
                actionLabel: 'Ver tudo',
              ),
              const EmptyState(
                emoji: '📡',
                title: 'Título',
                subtitle: 'Subtítulo',
                actionLabel: 'Tentar novamente',
                onAction: _noop,
              ),
            ],
          ),
        ),
  };

  // Tela inicial com notícias: backend falso que devolve 8 notícias por tema.
  setUp(() {
    NewsApi.client = MockClient((request) async {
      final category =
          request.url.queryParameters['category'] ?? 'Inteligência Artificial';
      final items = List.generate(
        8,
        (i) => {
          'id': '$category-$i',
          'title': 'Notícia $i de $category com um título razoavelmente longo',
          'summary': 'Resumo $i',
          'content': 'Conteúdo $i',
          'url': 'https://example.com/$i',
          'image_url': i.isEven ? 'https://example.com/$i.jpg' : null,
          'source': 'Tecnoblog',
          'category': category,
          'published_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({'items': items, 'total': 8, 'page': 1, 'limit': 30}),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  });

  for (final size in sizes.entries) {
    testWidgets('início com notícias · ${size.key}', (tester) async {
      await pumpScreen(
        tester,
        size.value,
        AppLook.light,
        Scaffold(
          body: HomePage(
            profile: profile,
            onOpenExplore: () {},
            onOpenProfile: () {},
            onAddFavorite: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Destaques para você'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Aba de um tema que não é favorito: mostra a dica de adicionar.
      await tester.scrollUntilVisible(
        find.text('Games'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView).at(1), // abas de temas
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text('Games'));
      await tester.pump();
      await tester.tap(find.text('Games'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Curtiu Games?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lista paginada mostra 3 notícias por vez', (tester) async {
    final many = List.generate(
      8,
      (i) => NewsArticle(
        id: 'n$i',
        category: 'Mobile',
        title: 'Notícia número $i',
        summary: 'Resumo',
        content: 'Conteúdo',
        source: 'Tecnoblog',
        url: 'https://example.com/$i',
        imageUrl: null,
        publishedAt: DateTime.now(),
      ),
    );

    await pumpScreen(
      tester,
      sizes['celular pequeno']!,
      AppLook.light,
      Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [PagedNewsList(articles: many)],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Página 1: notícias 0, 1 e 2.
    expect(find.byType(NewsListTile), findsNWidgets(3));
    expect(find.text('Notícia número 0'), findsOneWidget);
    expect(find.text('Ler mais'), findsNWidgets(3));

    // Avança duas páginas: a última (3) tem só 2 notícias (6 e 7).
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Próximas'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byType(NewsListTile), findsNWidgets(2));
    expect(find.text('Notícia número 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed busca a próxima página ao chegar perto do fim', (
    tester,
  ) async {
    final pagesRequested = <int>[];

    // Backend falso com 40 notícias, 15 por página.
    NewsApi.client = MockClient((request) async {
      final page = int.parse(request.url.queryParameters['page'] ?? '1');
      pagesRequested.add(page);
      final items = List.generate(15, (i) {
        final n = (page - 1) * 15 + i;
        return {
          'id': 'n$n',
          'title': 'Notícia $n do feed',
          'summary': 'Resumo $n',
          'content': 'Conteúdo $n',
          'url': 'https://example.com/$n',
          'image_url': null,
          'source': 'Tecnoblog',
          'category': 'Mobile',
          'published_at': DateTime.now().toUtc().toIso8601String(),
        };
      });
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({'items': items, 'total': 40, 'page': page, 'limit': 15}),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await pumpScreen(
      tester,
      sizes['celular pequeno']!,
      AppLook.light,
      Scaffold(body: FeedPage(favorites: profile.favoriteCategories)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(pagesRequested, [1], reason: 'pedidos feitos na abertura');
    expect(
      find.text('Notícia 0 do feed'),
      findsOneWidget,
      reason: 'primeiro cartão do feed na tela',
    );

    // Rola aos poucos até o fim da lista: a página 2 deve ser pedida sozinha.
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      pagesRequested,
      contains(2),
      reason: 'páginas pedidas depois de rolar: $pagesRequested',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('abertura mostra o logo e depois abre o app', (tester) async {
    await pumpScreen(
      tester,
      sizes['celular pequeno']!,
      AppLook.light,
      const SplashGate(child: Text('Página inicial')),
    );

    // Durante a abertura: logo na tela e o app ainda não.
    expect(find.byType(TechNewsLogo), findsOneWidget);
    expect(find.text('Página inicial'), findsNothing);

    // Depois da animação (e da virada de tela), abre o app.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Página inicial'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Cada tela em todas as aparências (cores, logo e animações diferentes).
  for (final look in AppLook.values) {
    for (final size in sizes.entries) {
      for (final screen in screens.entries) {
        testWidgets(
          '${screen.key} · ${size.key} · ${look.label}',
          (tester) async {
            await pumpScreen(tester, size.value, look, screen.value());
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

void _noop() {}
