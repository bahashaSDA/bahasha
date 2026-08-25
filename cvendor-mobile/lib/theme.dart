import 'package:flutter/material.dart';

/// CVendor shares the Bahasha offertory look — white canvas, Inter type, and the
/// offertory green — so the hub app and the giver app read as one product.
class HubColors {
  HubColors._();
  static const green = Color(0xFF008805);
  static const greenBright = Color(0xFF12B76A);
  static const surface = Color(0xFFFFFFFF);
  static const panel = Color(0xFFF4FBF5);
  static const ink = Color(0xFF14141A);
  static const inkMuted = Color(0xFF6B6B76);
  static const border = Color(0x14000000);
  static const danger = Color(0xFFE03131);
  static const warning = Color(0xFFE8A13A);
  static const success = Color(0xFF008805);

  // Legacy aliases kept so existing references keep compiling.
  static const indigo = green;
  static const panelGreen = panel;
}

ThemeData hubTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: HubColors.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HubColors.green,
      primary: HubColors.green,
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

/// A soft, faded cluster of fruit in a corner — the offertory motif, reused as a
/// gentle background flourish on the hub screens.
class FruitBackdrop extends StatelessWidget {
  const FruitBackdrop({super.key, this.child});
  final Widget? child;

  static const _fruits = <({String asset, double left, double top, double size, double opacity})>[
    (asset: 'assets/fruits/tithe.png', left: -40, top: -30, size: 180, opacity: 0.10),
    (asset: 'assets/fruits/offering.png', left: 0.72, top: 0.02, size: 150, opacity: 0.10),
    (asset: 'assets/fruits/mission.png', left: 0.02, top: 0.80, size: 150, opacity: 0.08),
    (asset: 'assets/fruits/church_budget.png', left: 0.70, top: 0.78, size: 170, opacity: 0.08),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    return Stack(children: [
      Positioned.fill(child: ColoredBox(color: HubColors.surface)),
      for (final f in _fruits)
        Positioned(
          left: f.left <= 1 ? f.left * w : f.left,
          top: f.top <= 1 ? f.top * h : f.top,
          width: f.size,
          height: f.size,
          child: IgnorePointer(
            child: Opacity(opacity: f.opacity, child: Image.asset(f.asset, fit: BoxFit.contain)),
          ),
        ),
      if (child != null) Positioned.fill(child: child!),
    ]);
  }
}
