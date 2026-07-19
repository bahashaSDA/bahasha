import 'package:flutter/material.dart';

/// CVendor shares the Bahasha palette so the two apps read as one product.
class HubColors {
  HubColors._();
  static const indigo = Color(0xFF231F4F);
  static const panelGreen = Color(0xFFD1EFBD);
  static const green = Color(0xFF89D385);
  static const cyan = Color(0xFF6CD1F0);
  static const violet = Color(0xFFA1A1F7);
  static const surface = Color(0xFFF6F8F4);
  static const ink = Color(0xFF231F4F);
  static const inkMuted = Color(0xFF6B7280);
  static const danger = Color(0xFFE03131);
  static const warning = Color(0xFFE8A13A);
  static const success = Color(0xFF2F9E44);
}

ThemeData hubTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: HubColors.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HubColors.indigo,
      primary: HubColors.indigo,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HubColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: HubColors.ink,
    ),
  );
}
