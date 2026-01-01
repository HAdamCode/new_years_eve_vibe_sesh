import 'package:flutter/material.dart';

/// App color palette - warm, spiritual, and inviting
class AppColors {
  // Primary - Rich warm brown/burgundy
  static const primary = Color(0xFF8B4D5C);
  static const primaryLight = Color(0xFFBD7A8A);
  static const primaryDark = Color(0xFF5C2D3A);

  // Secondary - Soft gold/amber
  static const secondary = Color(0xFFD4A853);
  static const secondaryLight = Color(0xFFE8C97A);
  static const secondaryDark = Color(0xFFB08A3A);

  // Tertiary - Calm sage green
  static const tertiary = Color(0xFF7A9E7E);
  static const tertiaryLight = Color(0xFFA8C5AB);
  static const tertiaryDark = Color(0xFF5A7A5E);

  // Neutrals
  static const cream = Color(0xFFFAF7F2);
  static const warmWhite = Color(0xFFFFFDF9);
  static const warmGray = Color(0xFF6B635B);
  static const darkBrown = Color(0xFF2D2622);

  // Semantic
  static const success = Color(0xFF68A868);
  static const error = Color(0xFFBF4D4D);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primary.withValues(alpha: 0.12),
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.darkBrown,
        secondaryContainer: AppColors.secondary.withValues(alpha: 0.15),
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.tertiary.withValues(alpha: 0.15),
        onTertiaryContainer: AppColors.tertiaryDark,
        surface: AppColors.warmWhite,
        onSurface: AppColors.darkBrown,
        surfaceContainerHighest: AppColors.cream,
        outline: AppColors.warmGray.withValues(alpha: 0.5),
        outlineVariant: AppColors.warmGray.withValues(alpha: 0.2),
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.warmWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.darkBrown,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: _textTheme,
      iconTheme: IconThemeData(
        color: AppColors.warmGray,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.warmGray.withValues(alpha: 0.15),
        thickness: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.tertiary;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.warmGray,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerHeight: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final darkSurface = Color(0xFF1A1614);
    final darkCard = Color(0xFF252120);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.darkBrown,
        primaryContainer: AppColors.primary.withValues(alpha: 0.25),
        onPrimaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.darkBrown,
        secondaryContainer: AppColors.secondary.withValues(alpha: 0.25),
        onSecondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.tertiaryLight,
        onTertiary: AppColors.darkBrown,
        tertiaryContainer: AppColors.tertiary.withValues(alpha: 0.25),
        onTertiaryContainer: AppColors.tertiaryLight,
        surface: darkSurface,
        onSurface: AppColors.cream,
        surfaceContainerHighest: darkCard,
        outline: AppColors.cream.withValues(alpha: 0.3),
        outlineVariant: AppColors.cream.withValues(alpha: 0.1),
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: darkSurface,
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: _textTheme,
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.cream.withValues(alpha: 0.6),
        indicatorColor: AppColors.primaryLight,
        indicatorSize: TabBarIndicatorSize.label,
        dividerHeight: 0,
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}
