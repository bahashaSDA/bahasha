import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Assembles the ThemeData from the design tokens. Kept thin: the screens do
/// their own precise layout to match the Figma, and lean on the theme only for
/// defaults (font family, colour scheme, splash behaviour).
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.indigo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.indigo,
        primary: AppColors.indigo,
        secondary: AppColors.categoryGreen,
        surface: AppColors.panelGreen,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: AppTypography.fontFamily),
      // The design has no ripple bleed on the flat colour bars; use a soft
      // highlight instead of the default splash so taps feel premium, not loud.
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
