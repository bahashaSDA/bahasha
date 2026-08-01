import 'package:flutter/material.dart';

/// The offertory basket that holds EXACTLY the fruits the giver chose. Built
/// from a REAL wicker basket (empty, cream-lined, with handle — derived from the
/// designer's basket photo) with the chosen fruits (transparent cut-outs)
/// nestled into the bowl and the real cream lip layered in front, so the fruits
/// look genuinely inside the basket — matching the Figma. Each fruit drops in
/// with a staggered animation.
class FruitBasket extends StatelessWidget {
  const FruitBasket({
    super.key,
    required this.assets,
    required this.animation,
    this.size = 307,
  });

  /// Fruit image paths for the chosen giving types, in order.
  final List<String> assets;
  final Animation<double> animation;
  final double size;

  // basket_lip.png native aspect (front cream lip + woven body crop).
  static const double _lipAspect = 405 / 900;

  @override
  Widget build(BuildContext context) {
    final s = size;
    final n = assets.length;
    final perRow = n <= 4 ? n : (n / 2).ceil();
    final fruitSize = (n <= 1 ? 0.54 : n <= 2 ? 0.50 : n <= 4 ? 0.45 : n <= 6 ? 0.37 : 0.31) * s;
    final step = fruitSize * 0.60;
    final baseBottom = 0.635 * s; // fruit bottoms sink to the lip, tucked inside
    final lipH = s * _lipAspect;

    final fruits = <Widget>[];
    for (var i = 0; i < n; i++) {
      final row = i < perRow ? 0 : 1;
      final idxInRow = i - row * perRow;
      final countInRow = row == 0 ? (n < perRow ? n : perRow) : n - perRow;
      final cx = s * 0.47 + (idxInRow - (countInRow - 1) / 2) * step;
      final cy = baseBottom - fruitSize / 2 - row * (fruitSize * 0.5) - (idxInRow.isOdd ? fruitSize * 0.05 : 0);

      final start = n <= 1 ? 0.0 : (i / n) * 0.5;
      final curve = CurvedAnimation(parent: animation, curve: Interval(start, 1, curve: Curves.easeOutBack));
      fruits.add(Positioned(
        left: cx - fruitSize / 2,
        top: cy - fruitSize / 2,
        width: fruitSize,
        height: fruitSize,
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.7), end: Offset.zero).animate(curve),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1).animate(curve),
              child: Image.asset(assets[i], fit: BoxFit.contain),
            ),
          ),
        ),
      ));
    }

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Empty real basket (handle, back rim, cream bowl) — behind the fruits.
          Positioned.fill(child: Image.asset('assets/baskets/basket_empty.png', fit: BoxFit.contain)),
          // Chosen fruits, nestled in the bowl.
          ...fruits,
          // Real cream lip + woven front — in front, so fruit bottoms tuck inside.
          Positioned(
            left: 0, right: 0, bottom: 0, height: lipH,
            child: Image.asset('assets/baskets/basket_lip.png', fit: BoxFit.fitWidth, alignment: Alignment.bottomCenter),
          ),
        ],
      ),
    );
  }
}
