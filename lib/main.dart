import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_settings.dart';
import 'app_update.dart';
import 'explore_page.dart';
import 'feed_page.dart';
import 'favorite_topics_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'logo.dart';
import 'motion.dart';
import 'profile_page.dart';
import 'saved_articles.dart';
import 'saved_page.dart';
import 'splash_screen.dart';
import 'supabase_service.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Independentes entre si: rodam juntas para a abertura ficar mais rápida.
  await Future.wait([appSettings.load(), initSupabase()]);
  // Sem "manter conectado", cada abertura do app começa pelo login.
  await SupabaseService.signOutIfNotRemembered(appSettings.rememberLogin);
  runApp(const TechNewsApp());
}

// ======================================================
// APLICATIVO
// ======================================================

class TechNewsApp extends StatelessWidget {
  const TechNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tech News',
        // Trocar a aparência anima as cores do app inteiro.
        theme: buildTheme(appSettings.look),
        themeAnimationDuration: const Duration(milliseconds: 450),
        home: const SplashGate(child: AuthGate()),
      ),
    );
  }
}

// ======================================================
// PORTEIRO DE AUTENTICAÇÃO
// Sem sessão → cadastro/login. Sem temas → escolher temas. Senão → app.
// ======================================================

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? authSubscription;

  UserProfile? profile;
  String? loadedUserId;
  bool loadingUser = false;
  String? error;

  // Código do "esqueci a senha" validado: falta escolher a nova senha.
  bool recoveringPassword = false;

  @override
  void initState() {
    super.initState();
    // Dispara logo ao assinar, com a sessão salva (se houver).
    authSubscription = SupabaseService.authChanges.listen(onAuthChange);
    // Procura versão nova do app (só no Android) depois da primeira tela.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => checkForAppUpdate(context),
    );
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  void onAuthChange(AuthState state) {
    final user = state.session?.user;

    if (state.event == AuthChangeEvent.passwordRecovery) {
      setState(() {
        recoveringPassword = true;
      });
    }

    if (user == null) {
      savedArticles.clear();
      setState(() {
        profile = null;
        loadedUserId = null;
        error = null;
        recoveringPassword = false;
      });
    } else if (user.id != loadedUserId && !loadingUser) {
      loadUser();
    }
  }

  Future<void> loadUser() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    setState(() {
      loadingUser = true;
      error = null;
    });

    try {
      final loaded = await SupabaseService.loadProfile();
      await savedArticles.load();
      if (!mounted) return;
      setState(() {
        profile = loaded;
        loadedUserId = userId;
        loadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loadingUser = false;
        error = 'Verifique sua internet e tente de novo.';
      });
    }
  }

  void updateProfile(UserProfile updated) {
    setState(() {
      profile = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (SupabaseService.currentUser == null) {
      return const AuthFlow();
    }

    if (recoveringPassword) {
      return NewPasswordForm(
        onDone: () => setState(() {
          recoveringPassword = false;
        }),
      );
    }

    if (error != null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            emoji: '📡',
            title: 'Não conseguimos carregar sua conta',
            subtitle: error!,
            actionLabel: 'Tentar novamente',
            onAction: loadUser,
          ),
        ),
      );
    }

    final current = profile;
    if (current == null) {
      return const _SplashScreen();
    }

    // Primeiro acesso: escolher os temas antes de entrar.
    if (current.favoriteCategories.isEmpty) {
      return FavoriteTopicsPage(
        initial: const [],
        isOnboarding: true,
        firstName: current.name.isNotEmpty ? current.firstName : '',
        onSaved: (chosen) =>
            updateProfile(current.copyWith(favoriteCategories: chosen)),
      );
    }

    return AppShell(profile: current, onProfileChanged: updateProfile);
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Appear(child: TechNewsLogo(height: 64)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              'Preparando suas notícias...',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// NAVEGAÇÃO PRINCIPAL (usuário logado e com temas)
// ======================================================

class AppShell extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileChanged;

  const AppShell({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedPage = 0;

  // Abas já visitadas. As outras só são montadas (e só buscam notícias) na
  // primeira vez que o usuário abre cada uma, em vez de tudo na abertura.
  final Set<int> visited = {0};

  void goTo(int index) {
    setState(() {
      selectedPage = index;
      visited.add(index);
    });
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> editTopics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => FavoriteTopicsPage(
          initial: widget.profile.favoriteCategories,
          onSaved: (chosen) {
            Navigator.of(routeContext).pop();
            widget.onProfileChanged(
              widget.profile.copyWith(favoriteCategories: chosen),
            );
            showMessage('Temas atualizados. Sua tela inicial já mudou. ✨');
          },
        ),
      ),
    );
  }

  Future<void> addFavorite(String category) async {
    final updated = [...widget.profile.favoriteCategories, category];
    // Mantém a mesma ordem da lista de temas.
    final ordered = topics
        .map((topic) => topic.category)
        .where(updated.contains)
        .toList();

    try {
      await SupabaseService.updateFavoriteCategories(ordered);
      widget.onProfileChanged(
        widget.profile.copyWith(favoriteCategories: ordered),
      );
      showMessage('$category agora está nos seus temas. 💜');
    } catch (_) {
      showMessage('Não foi possível adicionar o tema.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        profile: widget.profile,
        onOpenExplore: () => goTo(2),
        onOpenProfile: () => goTo(4),
        onAddFavorite: addFavorite,
      ),
      FeedPage(favorites: widget.profile.favoriteCategories),
      const ExplorePage(),
      SavedPage(onGoHome: () => goTo(0)),
      ProfilePage(
        profile: widget.profile,
        onEditTopics: editTopics,
        onLogout: SupabaseService.signOut,
      ),
    ];

    return Scaffold(
      body: AmbientBackground(
        child: IndexedStack(
          index: selectedPage,
          children: [
            for (var i = 0; i < pages.length; i++)
              visited.contains(i) ? pages[i] : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: savedArticles,
        builder: (context, _) {
          final savedCount = savedArticles.items.length;

          return NavigationBar(
            selectedIndex: selectedPage,
            onDestinationSelected: goTo,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Início',
              ),
              const NavigationDestination(
                icon: Icon(Icons.dynamic_feed_outlined),
                selectedIcon: Icon(Icons.dynamic_feed_rounded),
                label: 'Feed',
              ),
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: savedCount > 0,
                  label: Text('$savedCount'),
                  child: const Icon(Icons.bookmark_border_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: savedCount > 0,
                  label: Text('$savedCount'),
                  child: const Icon(Icons.bookmark_rounded),
                ),
                label: 'Salvos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          );
        },
      ),
    );
  }
}
