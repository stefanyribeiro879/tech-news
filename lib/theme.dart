import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ======================================================
// CORES DO APP
// Tons quentes (creme e ameixa) com o roxo da marca como destaque.
// ======================================================

class AppColors {
  static const purple = Color(0xFF6C5CE7);
  static const lightPurple = Color(0xFF9C8CFF);
  static const peach = Color(0xFFFF9F7A);

  // Tema claro
  static const cream = Color(0xFFF8F4EE);
  static const creamCard = Color(0xFFFFFFFF);
  static const creamChip = Color(0xFFF0E9E0);
  static const ink = Color(0xFF2A2433);
  static const inkSoft = Color(0xFF7A7185);
  static const creamLine = Color(0xFFE8E0D6);

  // Tema escuro
  static const plum = Color(0xFF16131D);
  static const plumCard = Color(0xFF211D2A);
  static const plumChip = Color(0xFF2B2636);
  static const mist = Color(0xFFF3EFF7);
  static const mistSoft = Color(0xFFA59FB0);
  static const plumLine = Color(0xFF332D3F);
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colors = ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    brightness: brightness,
  ).copyWith(
    primary: isDark ? AppColors.lightPurple : AppColors.purple,
    onPrimary: Colors.white,
    secondary: AppColors.peach,
    surface: isDark ? AppColors.plum : AppColors.cream,
    onSurface: isDark ? AppColors.mist : AppColors.ink,
    onSurfaceVariant: isDark ? AppColors.mistSoft : AppColors.inkSoft,
    surfaceContainerLowest: isDark ? AppColors.plumCard : AppColors.creamCard,
    surfaceContainer: isDark ? AppColors.plumChip : AppColors.creamChip,
    outlineVariant: isDark ? AppColors.plumLine : AppColors.creamLine,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
  );

  return base.copyWith(
    scaffoldBackgroundColor: colors.surface,
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surfaceContainerLowest,
      indicatorColor: colors.primary.withValues(alpha: 0.14),
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
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colors.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        textStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: colors.outlineVariant),
  );
}

// Atalhos: context.colors.primary, context.isDark
extension ThemeShortcuts on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
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

  // Fundo suave para pílulas e cartões do tema.
  Color background(BuildContext context) =>
      color.withValues(alpha: context.isDark ? 0.22 : 0.14);

  // Cor do texto com contraste suficiente nos dois temas.
  Color foreground(BuildContext context) {
    if (context.isDark) return color;
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
  }
}

const List<Topic> topics = [
  Topic(
    'Inteligência Artificial',
    Icons.psychology_outlined,
    Color(0xFF8B7CF6),
    'ChatGPT, Gemini, robôs e novidades de IA',
  ),
  Topic(
    'Mobile',
    Icons.smartphone_rounded,
    Color(0xFF2BB5A0),
    'Celulares, Android, iPhone e apps',
  ),
  Topic(
    'Games',
    Icons.sports_esports_outlined,
    Color(0xFFFF7A6B),
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
    Color(0xFF4A9FE8),
    'Outras notícias do mundo da tecnologia',
  ),
];

Topic topicOf(String category) => topics.firstWhere(
      (topic) => topic.category == category,
      orElse: () => topics.last,
    );
