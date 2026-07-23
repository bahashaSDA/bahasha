import 'package:flutter/material.dart';

/// Pixel-perfect layout against the Figma design frame (420 × 912).
///
/// Every Bahasha screen is authored in Figma at 420×912. To reproduce a screen
/// exactly on any Android device, we scale the whole 420-wide coordinate system
/// by `width / 420` and lay elements out with their literal Figma left/top/size.
/// The result is the identical design, proportionally, on every screen width.
///
/// Usage:
/// ```dart
/// PixelCanvas(
///   background: AppColors.panelGreen,
///   builder: (context, px) => [
///     px.text(40, 222, 'Tithe', size: 32),
///     px.at(356, 69, size: 24, child: menuIcon),
///   ],
/// )
/// ```
class PixelCanvas extends StatelessWidget {
  const PixelCanvas({
    super.key,
    required this.builder,
    this.background,
    this.scrollable = false,
  });

  /// Returns the positioned children, given a [Px] helper bound to the scale.
  final List<Widget> Function(BuildContext context, Px px) builder;
  final Color? background;

  /// When the design is taller than the viewport, allow vertical scrolling.
  final bool scrollable;

  static const double designWidth = 420;
  static const double designHeight = 912;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / designWidth;
        final px = Px(scale);
        final canvasHeight = designHeight * scale;

        final stack = SizedBox(
          width: width,
          height: canvasHeight,
          child: Stack(clipBehavior: Clip.none, children: builder(context, px)),
        );

        final content = scrollable
            ? SingleChildScrollView(child: stack)
            : stack;

        return Container(color: background, width: width, height: constraints.maxHeight, child: content);
      },
    );
  }
}

/// Scale-bound placement helpers. All inputs are literal Figma design pixels.
class Px {
  const Px(this.scale);

  /// device px per design px (width / 420).
  final double scale;

  /// Scale a single design measurement to device pixels.
  double call(double designPx) => designPx * scale;

  /// Position a child at an exact design rect. If [width]/[height] are omitted
  /// the child sizes itself (still offset by left/top).
  Widget at(double left, double top, {double? width, double? height, required Widget child}) {
    return Positioned(
      left: left * scale,
      top: top * scale,
      width: width == null ? null : width * scale,
      height: height == null ? null : height * scale,
      child: child,
    );
  }

  /// A full-width design element (e.g. an 80px colour bar) at a given top.
  Widget band(double top, double height, Color color, {double left = 0, BoxShadow? shadow}) {
    return Positioned(
      left: left * scale,
      top: top * scale,
      width: (420 - left) * scale,
      height: height * scale,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, boxShadow: shadow == null ? null : [shadow]),
      ),
    );
  }

  /// Text placed at an exact design position with a design font size.
  Widget text(
    double left,
    double top,
    String value, {
    required double size,
    Color color = const Color(0xFF231F4F),
    FontWeight weight = FontWeight.w300,
    double? width,
    double height = 1.0,
    TextAlign align = TextAlign.left,
    int? maxLines,
    bool ellipsis = false,
  }) {
    return Positioned(
      left: left * scale,
      top: top * scale,
      width: width == null ? null : width * scale,
      child: Text(
        value,
        textAlign: align,
        maxLines: maxLines,
        overflow: ellipsis ? TextOverflow.ellipsis : null,
        style: TextStyle(
          fontFamily: 'BahashaSans',
          fontWeight: weight,
          fontSize: size * scale,
          height: height,
          color: color,
        ),
      ),
    );
  }
}
