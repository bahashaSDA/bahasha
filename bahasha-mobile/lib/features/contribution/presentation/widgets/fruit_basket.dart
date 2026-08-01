import 'package:flutter/material.dart';

/// The offertory basket that holds EXACTLY the fruits the giver chose — nothing
/// they didn't. Built from a real wicker basket photo (basket_front.png: the
/// cream-lined front lip + woven body) layered IN FRONT of the chosen fruits
/// (transparent cut-outs), so the fruits look genuinely nestled inside the
/// basket. Each fruit drops in with a staggered animation.
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

  // The real basket-front asset's native aspect ratio.
  static const double _basketAspect = 250 / 736;

  @override
  Widget build(BuildContext context) {
    final w = size;
    final boxH = size;
    final basketH = w * _basketAspect;
    final frontTop = boxH - basketH; // y where the real basket lip begins
    final n = assets.length;

    final perRow = n <= 4 ? n : (n / 2).ceil();
    final fruitSize = (n <= 2 ? 0.52 : n <= 4 ? 0.46 : n <= 6 ? 0.36 : 0.30) * w;
    final step = fruitSize * 0.62;
    // Fruit bottoms sink into the basket lip so they read as tucked inside
    // (verified against a rendered composite of 1/3/6 fruits).
    final baseBottom = frontTop + basketH * 0.58;

    final fruits = <Widget>[];
    for (var i = 0; i < n; i++) {
      final row = i < perRow ? 0 : 1;
      final idxInRow = i - row * perRow;
      final countInRow = row == 0 ? (n < perRow ? n : perRow) : n - perRow;
      final cx = w / 2 + (idxInRow - (countInRow - 1) / 2) * step;
      final cy = baseBottom - fruitSize / 2 - row * (fruitSize * 0.50) - (idxInRow.isOdd ? fruitSize * 0.06 : 0);

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
      width: w,
      height: boxH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft contact shadow so the pile has weight.
          Positioned(
            left: w * 0.18, right: w * 0.18, top: frontTop - fruitSize * 0.15, height: basketH * 0.5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, spreadRadius: 2)],
              ),
            ),
          ),
          // Chosen fruits (behind the basket front).
          ...fruits,
          // The real basket, in front, so fruit bottoms tuck inside it.
          Positioned(
            left: 0, right: 0, bottom: 0, height: basketH,
            child: Image.asset('assets/baskets/basket_front.png',
                fit: BoxFit.fitWidth, alignment: Alignment.bottomCenter),
          ),
        ],
      ),
    );
  }
}
