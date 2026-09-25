import 'package:flutter/material.dart';

/// The Bahasha palette, taken directly from the Figma design.
///
/// Every colour the UI uses is named here; screens never hard-code a hex value.
class AppColors {
  AppColors._();

  // --- Keypad / wheel redesign (Figma frames 621:* – 707:*) -----------------

  /// Action blue — send icon, "Send", links, selected arrows (#1774FF).
  static const Color blue = Color(0xFF1774FF);

  /// Destructive / missing-vendor red (#CF0407).
  static const Color red = Color(0xFFCF0407);

  /// Unselected wheel items and info icon (#868686).
  static const Color wheelGrey = Color(0xFF868686);

  /// Placeholder text, dividers and the "off" toggle (#C8C8C8).
  static const Color placeholder = Color(0xFFC8C8C8);

  /// Selected-card border (#D9D9D9).
  static const Color cardBorder = Color(0xFFD9D9D9);

  /// The "Bahasha" pill on Settings (#F5F5F5).
  static const Color pill = Color(0xFFF5F5F5);

  /// Keypad digits (#272727).
  static const Color keypadInk = Color(0xFF272727);

  /// Empty vendor avatar (#E4E4E4).
  static const Color vendorMissing = Color(0xFFE4E4E4);

  /// The sheet's top shadow, rgba(23,116,255,0.25).
  static const Color sheetShadow = Color(0x401774FF);

  // --- Legacy tokens (registration / customize / history screens) -----------

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

  static const Color ink = Color(0xFF231F4F);
  static const Color inkMuted = Color(0xFF404040);
  static const Color onIndigo = Color(0xFFFFFFFF);
  static const Color panelGradientTop = Color(0xFFDEFFCD);
  static const Color panelGradientBottom = Color(0xFFFFFFFF);
}
