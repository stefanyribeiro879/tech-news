import 'package:supabase_flutter/supabase_flutter.dart';

import 'news_api.dart';

// ======================================================
// CONFIGURAÇÃO DO SUPABASE
// A publishable key pode ficar no app: a segurança vem das regras (RLS)
// definidas em supabase/schema.sql. Nunca coloque a secret key aqui.
// ======================================================

const String supabaseUrl = 'https://fuwdcbznpyvydkmdaczv.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_DKP1Rn_1xKD0yRSxJbvk0g_RnhnbG2I';

Future<void> initSupabase() {
  return Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}

SupabaseClient get _db => Supabase.instance.client;

// ======================================================
// PERFIL
// ======================================================

class UserProfile {
  final String name;
  final String email;
  final List<String> favoriteCategories;

  const UserProfile({
    required this.name,
    required this.email,
    required this.favoriteCategories,
  });

  UserProfile copyWith({List<String>? favoriteCategories}) {
    return UserProfile(
      name: name,
      email: email,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
    );
  }

  String get firstName {
    final first = name.trim().split(' ').first;
    return first.isNotEmpty ? first : 'leitor(a)';
  }

  String get initial =>
      (name.trim().isNotEmpty ? name.trim() : email).substring(0, 1).toUpperCase();
}

// ======================================================
// LOGIN, CADASTRO E DADOS DO USUÁRIO
// ======================================================

class SupabaseService {
  static User? get currentUser => _db.auth.currentUser;

  static Stream<AuthState> get authChanges => _db.auth.onAuthStateChange;

  static Future<void> signIn(String email, String password) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  // Retorna true se já entrou; false se o Supabase exigir confirmar o e-mail.
  static Future<bool> signUp(String name, String email, String password) async {
    final response = await _db.auth.signUp(
      email: email,
      password: password,
      data: {'name': name}, // usado pelo gatilho que cria o perfil
    );
    return response.session != null;
  }

  static Future<void> signOut() => _db.auth.signOut();

  // Chamado ao abrir o app: sem "manter conectado", começa deslogado.
  static Future<void> signOutIfNotRemembered(bool rememberLogin) async {
    if (rememberLogin || currentUser == null) return;
    try {
      await _db.auth.signOut();
    } catch (_) {
      // Sem internet: a sessão local é descartada mesmo assim.
    }
  }

  static Future<UserProfile> loadProfile() async {
    final user = currentUser!;
    final row = await _db
        .from('profiles')
        .select('name, favorite_categories')
        .eq('id', user.id)
        .maybeSingle();

    return UserProfile(
      name: (row?['name'] as String?) ?? '',
      email: user.email ?? '',
      favoriteCategories: List<String>.from(
        (row?['favorite_categories'] as List?) ?? const [],
      ),
    );
  }

  static Future<void> updateFavoriteCategories(List<String> categories) async {
    await _db
        .from('profiles')
        .update({'favorite_categories': categories})
        .eq('id', currentUser!.id);
  }

  // ------------------------------------------------------
  // NOTÍCIAS SALVAS
  // ------------------------------------------------------

  static Future<List<NewsArticle>> loadSaved() async {
    final rows = await _db
        .from('saved_articles')
        .select()
        .order('saved_at', ascending: false);

    return rows.map(NewsArticle.fromSavedRow).toList();
  }

  static Future<void> save(NewsArticle article) async {
    // O user_id é preenchido pelo banco (default auth.uid()).
    await _db.from('saved_articles').upsert(article.toSavedRow());
  }

  static Future<void> unsave(String articleId) async {
    await _db.from('saved_articles').delete().eq('article_id', articleId);
  }
}

// Mensagens de erro do Supabase em português.
String authErrorMessage(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirme seu e-mail pelo link enviado antes de entrar.';
    }
    if (message.contains('already registered')) {
      return 'Já existe uma conta com esse e-mail.';
    }
    if (message.contains('password')) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }
    if (message.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde alguns minutos.';
    }
    return error.message;
  }
  return 'Não foi possível conectar. Verifique sua internet.';
}
