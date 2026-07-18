import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography, matched to the Figma.
///
/// The design is set in "Elms Sans" (Light and Regular). That face is licensed
/// and not bundled; [fontFamily] points at the free geometric substitute
/// (Quicksand, bundled as `BahashaSans`). To ship the real design, add the Elms
/// Sans .ttf files under the `BahashaSans` family in pubspec.yaml — this one
/// constant is the ONLY place the family is named, so nothing else changes.
class AppTypography {
  AppTypography._();

  /// Swap target for the licensed face. Everything derives from this.
  static const String fontFamily = 'BahashaSans';

  /// The Figma weights: "Light" (w300) for content, "Regular" (w400) for the
  /// call to action.
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;

  /// Large category title on the panel — Figma 32px, Light, indigo.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontWeight: light,
    fontSize: 32,
    height: 1.0,
    color: AppColors.ink,
  );

  /// Supporting description — Figma 16px, Light, indigo, ~1.25 line height.
  static const TextStyle description = TextStyle(
    fontFamily: fontFamily,
    fontWeight: light,
    fontSize: 16,
    height: 1.3,
    color: AppColors.ink,
  );

  /// Category row label and entered amount — Figma 24px, Light.
  static const TextStyle rowLabel = TextStyle(
    fontFamily: fontFamily,
    fontWeight: light,
    fontSize: 24,
    height: 1.0,
    color: AppColors.ink,
  );

  /// "Send contributions" — Figma 24px, Regular, white.
  static const TextStyle action = TextStyle(
    fontFamily: fontFamily,
    fontWeight: regular,
    fontSize: 24,
    height: 1.0,
    color: AppColors.onIndigo,
  );
}
