import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Brand colors: canal teal (Upper Ganga Canal), marigold for dates and
// festivals, brick for heritage content.
const Color canal = Color(0xFF0F5E63);
const Color marigold = Color(0xFFE59A1C);
const Color brick = Color(0xFFA2412B);

/// Spacing scale. Use these instead of arbitrary SizedBox/EdgeInsets values.
class Space {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii: s for chips/badges/thumbnails, m for cards, l for heroes.
class Radii {
  static const double s = 8;
  static const double m = 14;
  static const double l = 20;
}

/// Semantic colors not covered by ColorScheme.
extension AppColors on ColorScheme {
  bool get _light => brightness == Brightness.light;
  Color get success => _light ? const Color(0xFF1E6B3A) : const Color(0xFF8FD6A4);
  Color get successContainer =>
      _light ? const Color(0xFFD5EEDC) : const Color(0xFF0F3A20);
  Color get onSuccessContainer =>
      _light ? const Color(0xFF0B3A1C) : const Color(0xFFB7F0C6);
}

ThemeData buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: canal,
    brightness: brightness,
    // Light-mode overrides keep the brand hues; dark mode uses the
    // seed-derived tones so contrast stays correct.
    primary: isLight ? canal : null,
    secondary: isLight ? const Color(0xFF8A5100) : null,
    secondaryContainer: isLight ? const Color(0xFFFFDDB0) : null,
    onSecondaryContainer: isLight ? const Color(0xFF2A1800) : null,
    tertiary: isLight ? brick : null,
  );

  final baseText = ThemeData(brightness: brightness).textTheme;
  final textTheme = GoogleFonts.muktaTextTheme(baseText).apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.m)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    listTileTheme: ListTileThemeData(
      selectedColor: scheme.onPrimaryContainer,
      selectedTileColor: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.primary,
    ),
  );
}
