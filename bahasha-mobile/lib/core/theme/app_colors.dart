import 'package:flutter/material.dart';

/// The Bahasha palette, taken directly from the Figma design.
///
/// Every colour the UI uses is named here; screens never hard-code a hex value.
/// The four category colours cycle in the exact order the design specifies, so
/// a category's colour is a function of its position, matching the mock.
class AppColors {
  AppColors._();

  /// Deep indigo — the scaffold background and the fixed "Send" bar.
  static const Color indigo = Color(0xFF231F4F);

  /// Light green — the top information panel.
  static const Color panelGreen = Color(0xFFD1EFBD);

  /// Category row colours, in cycle order (Figma: green, cyan, violet).
  static const Color categoryGreen = Color(0xFF89D385);
  static const Color categoryCyan = Color(0xFF6CD1F0);
  static const Color categoryViolet = Color(0xFFA1A1F7);

  /// The recurring row-colour cycle. Index a category by its position.
  static const List<Color> categoryCycle = <Color>[
    panelGreen,
    categoryGreen,
    categoryCyan,
    categoryViolet,
  ];

  /// Ink used on light surfaces. The Figma uses indigo for headings on the
  /// panel and a soft charcoal for entered amounts on the contribution screen.
  static const Color ink = Color(0xFF231F4F);
  static const Color inkMuted = Color(0xFF404040);

  /// Ink on the indigo bar.
  static const Color onIndigo = Color(0xFFFFFFFF);

  /// Panel gradient foot (Figma Rectangle 27: #DEFFCD → white). Used as the
  /// subtle fade under the panel content.
  static const Color panelGradientTop = Color(0xFFDEFFCD);
  static const Color panelGradientBottom = Color(0xFFFFFFFF);
}
