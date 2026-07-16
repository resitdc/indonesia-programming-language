import 'package:flutter/material.dart';

// ============================================================
// DESIGN TOKENS — Color, Spacing, Typography, Radius, Shadows
// ============================================================

class AppColors {
  // Primary
  static const primaryBlue = Color(0xFF2563EB); // Blue-600
  static const primaryLight = Color(0xFF3B82F6); // Blue-500
  static const primaryDark = Color(0xFF1D4ED8); // Blue-700

  // Accent
  static const accentCyan = Color(0xFF06B6D4); // Cyan-500
  static const accentLight = Color(0xFF22D3EE); // Cyan-400

  // Surfaces
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF111827); // Gray-900
  static const surfaceAltLight = Color(0xFFF9FAFB); // Gray-50
  static const surfaceAltDark = Color(0xFF1F2937); // Gray-800

  // Text
  static const textPrimaryLight = Color(0xFF111827);
  static const textPrimaryDark = Color(0xFFF9FAFB);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textSecondaryDark = Color(0xFF9CA3AF);

  // Borders
  static const borderLight = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFF374151);

  // Status
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double full = 999;
}

class AppShadows {
  static BoxShadow subtleLight = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );
  static BoxShadow cardLight = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
  static BoxShadow subtleDark = BoxShadow(
    color: Colors.black.withValues(alpha: 0.2),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );
  static BoxShadow cardDark = BoxShadow(
    color: Colors.black.withValues(alpha: 0.3),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
}

class AppTypography {
  static const String fontMono = 'JetBrains Mono';
  static const String fontUI = 'Inter';

  static TextStyle heading1(BuildContext context) => TextStyle(
    fontFamily: fontUI,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontFamily: fontUI,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle body(BuildContext context) => TextStyle(
    fontFamily: fontUI,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
    height: 1.5,
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontFamily: fontUI,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
  );

  static TextStyle mono(BuildContext context) => TextStyle(
    fontFamily: fontMono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

// ============================================================
// THEME DATA — Light & Dark, with custom design system
// ============================================================

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: AppColors.accentCyan,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.surfaceAltLight,
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.borderLight),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      scrolledUnderElevation: 1,
      shape: Border(bottom: BorderSide(color: AppColors.borderLight)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAltLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceAltLight,
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      labelStyle: const TextStyle(fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      side: const BorderSide(color: AppColors.borderLight),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      secondary: AppColors.accentLight,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.surfaceDark,
    cardTheme: CardThemeData(
      color: AppColors.surfaceAltDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.borderDark),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      scrolledUnderElevation: 1,
      shape: Border(bottom: BorderSide(color: AppColors.borderDark)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAltDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceAltDark,
      selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
      labelStyle: const TextStyle(fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      side: const BorderSide(color: AppColors.borderDark),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
    ),
  );
}

// ============================================================
// THEME PROVIDER
// ============================================================

enum AppThemeMode { light, dark }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.light;

  AppThemeMode get mode => _mode;
  bool get isDark => _mode == AppThemeMode.dark;

  void toggle() {
    _mode = isDark ? AppThemeMode.light : AppThemeMode.dark;
    notifyListeners();
  }

  void setMode(AppThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  ThemeData get themeData => isDark ? buildDarkTheme() : buildLightTheme();
}
