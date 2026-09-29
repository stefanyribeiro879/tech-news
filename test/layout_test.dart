// Desenha as telas em tamanho de celular e de computador para garantir que
// nada "estoura" o layout (as faixas amarelas e pretas do Flutter).
// Rodar com: flutter test

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tech_news/article_page.dart';
import 'package:tech_news/favorite_topics_page.dart';
import 'package:tech_news/home_page.dart';
import 'package:tech_news/login_page.dart';
import 'package:tech_news/news_api.dart';
import 'package:tech_news/profile_page.dart';
import 'package:tech_news/saved_page.dart';
import 'package:tech_news/supabase_service.dart';
import 'package:tech_news/theme.dart';
import 'package:tech_news/widgets.dart';

// Tema sem Google Fonts (os testes não acessam a internet).
ThemeData testTheme(Brightness brightness) {
  final theme = buildTheme(brightness);
  return theme.copyWith(textTheme: ThemeData(brightness: brightness).textTheme);
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
  Brightness brightness,
  Widget screen,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: testTheme(brightness), home: screen),
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
    'salvos (vazio)': () => Scaffold(body: SavedPage(onGoHome: () {})),
    'perfil': () => Scaffold(
          body: ProfilePage(
            profile: profile,
            onEditTopics: () {},
            onLogout: () {},
          ),
        ),
    'notícia': () => ArticlePage(article: article),
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
        Brightness.light,
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

  for (final brightness in Brightness.values) {
    for (final size in sizes.entries) {
      for (final screen in screens.entries) {
        testWidgets(
          '${screen.key} · ${size.key} · ${brightness.name}',
          (tester) async {
            await pumpScreen(tester, size.value, brightness, screen.value());
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

void _noop() {}
