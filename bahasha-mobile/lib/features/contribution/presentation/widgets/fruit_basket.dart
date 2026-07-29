import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The offertory basket that holds EXACTLY the fruits the giver chose — nothing
/// they didn't. The wicker basket is drawn (so it's empty by default) and the
/// chosen fruit images are clustered in its opening, each dropping in with a
/// staggered animation as the "adding to the basket" motion.
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

  @override
  Widget build(BuildContext context) {
    final w = size;
    final h = size * 0.98;
    final n = assets.length;

    // Cluster the chosen fruits in the basket opening. Up to five sit in one
    // row; more wrap to a second, slightly-raised row. Fruits overlap a little
    // so a full basket reads as full, a single fruit sits centred.
    final perRow = n <= 5 ? n : (n / 2).ceil();
    final fruitSize = (n <= 3 ? 0.34 : n <= 6 ? 0.28 : 0.24) * w;
    final step = fruitSize * 0.72;

    final placed = <Widget>[];
    for (var i = 0; i < n; i++) {
      final row = i < perRow ? 0 : 1;
      final idxInRow = i - row * perRow;
      final countInRow = row == 0 ? math.min(perRow, n) : n - perRow;
      final cx = w / 2 + (idxInRow - (countInRow - 1) / 2) * step;
      final cy = h * 0.40 - row * fruitSize * 0.42 + (idxInRow.isEven ? 0 : h * 0.015);

      // Staggered drop-in for each fruit.
      final start = n <= 1 ? 0.0 : (i / n) * 0.55;
      final curve = CurvedAnimation(parent: animation, curve: Interval(start, 1, curve: Curves.easeOutBack));
      placed.add(Positioned(
        left: cx - fruitSize / 2,
        top: cy - fruitSize / 2,
        width: fruitSize,
        height: fruitSize,
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero).animate(curve),
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
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _BasketPainter())),
          ...placed,
        ],
      ),
    );
  }
}

/// A stylised wicker basket: handle, woven body, and a cream cloth lining at the
/// rim — drawn so it starts empty and only the chosen fruits fill it.
class _BasketPainter extends CustomPainter {
  static const _tanLight = Color(0xFFE0C089);
  static const _tan = Color(0xFFC8A06A);
  static const _tanDark = Color(0xFFA9763F);
  static const _rim = Color(0xFF875327);
  static const _cloth = Color(0xFFEFE6D2);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final s = w / 307; // stroke scale

    // Handle.
    final handle = Path()
      ..moveTo(0.25 * w, 0.53 * h)
      ..cubicTo(0.25 * w, 0.10 * h, 0.75 * w, 0.10 * h, 0.75 * w, 0.53 * h);
    canvas.drawPath(handle, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 14 * s..color = _tanDark..strokeCap = StrokeCap.round);
    canvas.drawPath(handle, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 5 * s..color = _tanLight..strokeCap = StrokeCap.round);

    // Body bowl.
    final bowl = Path()
      ..moveTo(0.15 * w, 0.50 * h)
      ..lineTo(0.85 * w, 0.50 * h)
      ..lineTo(0.71 * w, 0.95 * h)
      ..quadraticBezierTo(0.50 * w, 1.02 * h, 0.29 * w, 0.95 * h)
      ..close();
    final bodyRect = Rect.fromLTWH(0.15 * w, 0.50 * h, 0.70 * w, 0.52 * h);
    canvas.drawPath(bowl, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [_tanLight, _tan, _tanDark],
      ).createShader(bodyRect));

    // Woven horizontal lines, clipped to the bowl.
    canvas.save();
    canvas.clipPath(bowl);
    final weave = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6 * s..color = _tanDark.withValues(alpha: 0.55);
    for (var i = 1; i <= 6; i++) {
      final y = 0.52 * h + i * 0.066 * h;
      final p = Path()
        ..moveTo(0.14 * w, y)
        ..quadraticBezierTo(0.5 * w, y + 0.02 * h, 0.86 * w, y);
      canvas.drawPath(p, weave);
    }
    // A couple of vertical staves for weave texture.
    for (final fx in [0.34, 0.5, 0.66]) {
      canvas.drawLine(Offset(fx * w, 0.52 * h), Offset((fx * 0.85 + 0.075) * w, 0.97 * h),
          Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2 * s..color = _tanDark.withValues(alpha: 0.35));
    }
    canvas.restore();

    // Cream cloth lining + rim.
    final rimRect = Rect.fromCenter(center: Offset(0.5 * w, 0.48 * h), width: 0.72 * w, height: 0.15 * h);
    canvas.drawOval(rimRect, Paint()..color = _cloth);
    canvas.drawOval(rimRect, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 6 * s..color = _rim);
  }

  @override
  bool shouldRepaint(covariant _BasketPainter oldDelegate) => false;
}
