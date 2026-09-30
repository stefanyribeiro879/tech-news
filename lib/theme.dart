import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ======================================================
// APARÊNCIAS DO APP
// Cada aparência define cores, intensidade das animações e as cores da logo.
// O usuário escolhe em Perfil > Aparência (lib/appearance_page.dart).
// ======================================================

// Quanto o app se mexe: rich = animações completas, simple = só o essencial.
enum MotionLevel { simple, normal, rich }

enum AppLook {
  light(
    label: 'Claro',
    description: 'Limpo e neutro, com o azul da marca nos detalhes.',
    brightness: Brightness.light,
    motion: MotionLevel.normal,
  ),
  dark(
    label: 'Escuro',
    description: 'Fundo grafite, confortável para ler à noite.',
    brightness: Brightness.dark,
    motion: MotionLevel.normal,
  ),
  lightVivid(
    label: 'Claro vivo',
    description: 'Cores vivas, degradês e animações por todo o app.',
    brightness: Brightness.light,
    motion: MotionLevel.rich,
  ),
  darkMono(
    label: 'Escuro preto e branco',
    description: 'Só preto e branco, com animações discretas.',
    brightness: Brightness.dark,
    motion: MotionLevel.simple,
  ),
  darkVivid(
    label: 'Escuro vivo',
    description: 'Noite colorida, com tons joviais e animações.',
    brightness: Brightness.dark,
    motion: MotionLevel.rich,
  );

  const AppLook({
    required this.label,
    required this.description,
    required this.brightness,
    required this.motion,
  });

  final String label;
  final String description;
  final Brightness brightness;
  final MotionLevel motion;

  AppPalette get palette => switch (this) {
    AppLook.light => AppPalette.light,
    AppLook.dark => AppPalette.dark,
    AppLook.lightVivid => AppPalette.lightVivid,
    AppLook.darkMono => AppPalette.darkMono,
    AppLook.darkVivid => AppPalette.darkVivid,
  };

  static AppLook fromName(String? name) => AppLook.values.firstWhere(
    (look) => look.name == name,
    orElse: () => AppLook.light,
  );
}

// ======================================================
// PALETAS
// brand = azul da logo. "accent" forma os degradês das versões vivas.
// ======================================================

class AppPalette {
  final Color background;
  final Color card;
  final Color chip;
  final Color line;
  final Color ink;
  final Color inkSoft;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final List<Color> accent; // degradê (1 cor = sem degradê)

  // Logo: marca "NT", palavra "Tech" e palavra "News".
  final List<Color> logoMark;
  final Color logoTech;
  final List<Color> logoNews;

  // Temas das notícias sem cor própria (versão preto e branco).
  final bool monochrome;

  const AppPalette({
    required this.background,
    required this.card,
    required this.chip,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.accent,
    required this.logoMark,
    required this.logoTech,
    required this.logoNews,
    this.monochrome = false,
  });

  static const brand = Color(0xFF2317FA);

  static const light = AppPalette(
    background: Color(0xFFF4F6FB),
    card: Color(0xFFFFFFFF),
    chip: Color(0xFFE9EDF5),
    line: Color(0xFFDDE3EE),
    ink: Color(0xFF0F172A),
    inkSoft: Color(0xFF5B6475),
    primary: brand,
    onPrimary: Colors.white,
    secondary: Color(0xFF0EA5E9),
    accent: [brand],
    logoMark: [brand],
    logoTech: Color(0xFF0F172A),
    logoNews: [brand],
  );

  static const dark = AppPalette(
    background: Color(0xFF0B0E14),
    card: Color(0xFF141922),
    chip: Color(0xFF1C2230),
    line: Color(0xFF252C3A),
    ink: Color(0xFFE6EAF2),
    inkSoft: Color(0xFF8B93A7),
    primary: Color(0xFF5B63FF),
    onPrimary: Colors.white,
    secondary: Color(0xFF38BDF8),
    accent: [Color(0xFF5B63FF)],
    // Azul mais claro que o da marca: o original some no fundo escuro.
    logoMark: [Color(0xFF6E76FF)],
    logoTech: Color(0xFFF1F4FA),
    logoNews: [Color(0xFF8A90FF)],
  );

  static const lightVivid = AppPalette(
    background: Color(0xFFF7F5FF),
    card: Color(0xFFFFFFFF),
    chip: Color(0xFFEEEAFE),
    line: Color(0xFFE2DCFB),
    ink: Color(0xFF14112B),
    inkSoft: Color(0xFF6B6591),
    primary: Color(0xFF4F2BFF),
    onPrimary: Colors.white,
    secondary: Color(0xFF00B8F0),
    accent: [Color(0xFF2317FA), Color(0xFF8B3DFF), Color(0xFFFF4FA3)],
    logoMark: [Color(0xFF2317FA), Color(0xFF8B3DFF)],
    logoTech: Color(0xFF14112B),
    logoNews: [Color(0xFF4F2BFF), Color(0xFFFF4FA3)],
  );

  static const darkMono = AppPalette(
    background: Color(0xFF000000),
    card: Color(0xFF111111),
    chip: Color(0xFF1A1A1A),
    line: Color(0xFF2A2A2A),
    ink: Color(0xFFFFFFFF),
    inkSoft: Color(0xFFA3A3A3),
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    secondary: Color(0xFFD4D4D4),
    accent: [Color(0xFFFFFFFF), Color(0xFFBDBDBD)],
    logoMark: [Color(0xFFFFFFFF)],
    logoTech: Color(0xFFFFFFFF),
    logoNews: [Color(0xFFBDBDBD)],
    monochrome: true,
  );

  static const darkVivid = AppPalette(
    background: Color(0xFF0E0B1F),
    card: Color(0xFF1A1533),
    chip: Color(0xFF241D45),
    line: Color(0xFF2F2757),
    ink: Color(0xFFF4F1FF),
    inkSoft: Color(0xFFA79FD1),
    primary: Color(0xFF7C5CFF),
    onPrimary: Colors.white,
    secondary: Color(0xFF22E4C7),
    accent: [Color(0xFF7C5CFF), Color(0xFFFF6AD5), Color(0xFF22E4C7)],
    logoMark: [Color(0xFF22E4C7), Color(0xFF7C5CFF)],
    logoTech: Color(0xFFF4F1FF),
    logoNews: [Color(0xFFFF6AD5), Color(0xFF7C5CFF)],
  );
}

// ======================================================
// EXTENSÃO DO TEMA
// Guarda a aparência atual dentro do ThemeData: context.look, context.palette.
// ======================================================

class AppStyle extends ThemeExtension<AppStyle> {
  final AppLook look;

  const AppStyle(this.look);

  @override
  AppStyle copyWith({AppLook? look}) => AppStyle(look ?? this.look);

  // Na troca de tema o Flutter anima as cores; a aparência muda no meio.
  @override
  AppStyle lerp(AppStyle? other, double t) =>
      (other != null && t >= 0.5) ? other : this;
}

ThemeData buildTheme(AppLook look) {
  final p = look.palette;
  final isDark = look.brightness == Brightness.dark;

  final colors =
      ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: look.brightness,
      ).copyWith(
        primary: p.primary,
        onPrimary: p.onPrimary,
        secondary: p.secondary,
        surface: p.background,
        onSurface: p.ink,
        onSurfaceVariant: p.inkSoft,
        surfaceContainerLowest: p.card,
        surfaceContainer: p.chip,
        outlineVariant: p.line,
        secondaryContainer: p.chip,
        onSecondaryContainer: p.ink,
        error: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD62839),
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: look.brightness,
    colorScheme: colors,
  );

  // Transição entre telas conforme a intensidade das animações.
  final transition = switch (look.motion) {
    MotionLevel.rich => const ZoomPageTransitionsBuilder(),
    MotionLevel.normal => const FadeUpwardsPageTransitionsBuilder(),
    MotionLevel.simple => const _FadePageTransitionsBuilder(),
  };

  return base.copyWith(
    extensions: [AppStyle(look)],
    scaffoldBackgroundColor: colors.surface,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values) platform: transition,
      },
    ),
    textTheme: GoogleFonts.nunitoTextTheme(
      base.textTheme,
    ).apply(bodyColor: colors.onSurface, displayColor: colors.onSurface),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surfaceContainerLowest,
      indicatorColor: colors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        minimumSize: const Size.fromHeight(54),
        textStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: colors.outlineVariant),
  );
}

// Transição só com esmaecer (aparência com animações simples).
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

// Atalhos: context.colors.primary, context.isDark, context.look, context.palette
extension ThemeShortcuts on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppLook get look => Theme.of(this).extension<AppStyle>()?.look ??
      (isDark ? AppLook.dark : AppLook.light);
  AppPalette get palette => look.palette;
  MotionLevel get motion => look.motion;

  // Degradê de destaque; nas aparências sem degradê, a cor principal pura.
  Gradient get accentGradient {
    final accent = palette.accent;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: accent.length == 1 ? [accent.first, accent.first] : accent,
    );
  }
}

// ======================================================
// TEMAS DAS NOTÍCIAS
// A categoria precisa ser igual à do backend.
// ======================================================

class Topic {
  final String category;
  final IconData icon;
  final Color color;
  final String description;

  const Topic(this.category, this.icon, this.color, this.description);

  // Nome curto para espaços pequenos (pílulas nos cartões).
  String get shortName =>
      category == 'Inteligência Artificial' ? 'IA' : category;

  // Cor do tema na aparência atual (cinza na versão preto e branco).
  Color tint(BuildContext context) =>
      context.palette.monochrome ? context.colors.onSurface : color;

  // Fundo suave para pílulas e cartões do tema.
  Color background(BuildContext context) =>
      tint(context).withValues(alpha: context.isDark ? 0.16 : 0.12);

  // Cor do texto com contraste suficiente nos dois temas.
  Color foreground(BuildContext context) {
    final base = tint(context);
    if (context.isDark) return base;
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
  }
}

const List<Topic> topics = [
  Topic(
    'Inteligência Artificial',
    Icons.psychology_outlined,
    Color(0xFF7C6CF6),
    'ChatGPT, Gemini, robôs e novidades de IA',
  ),
  Topic(
    'Mobile',
    Icons.smartphone_rounded,
    Color(0xFF14B8A6),
    'Celulares, Android, iPhone e apps',
  ),
  Topic(
    'Games',
    Icons.sports_esports_outlined,
    Color(0xFFF97366),
    'Consoles, lançamentos e e-sports',
  ),
  Topic(
    'Segurança',
    Icons.shield_outlined,
    Color(0xFFF2A93B),
    'Golpes, vazamentos e proteção de dados',
  ),
  Topic(
    'Geral',
    Icons.public_rounded,
    Color(0xFF3B82F6),
    'Outras notícias do mundo da tecnologia',
  ),
];

Topic topicOf(String category) => topics.firstWhere(
  (topic) => topic.category == category,
  orElse: () => topics.last,
);
