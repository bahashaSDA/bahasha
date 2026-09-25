import 'package:flutter/material.dart';
import '../../../../core/design/type.dart';
import '../../../../core/theme/app_colors.dart';

/// Where each part of the wheel sits, in Figma design pixels (frame 420×912).
/// The Category (621:54) and Send (621:76) frames place the wheel slightly
/// differently, so each screen passes its own measured geometry.
@immutable
class WheelGeometry {
  const WheelGeometry({
    required this.prevTop,
    required this.cardTop,
    required this.nextTop,
    required this.cardLeft,
    required this.textLeft,
    required this.trailingLeft,
  });

  /// Top of the unselected item above the card (Elms Sans Medium 20, #868686).
  final double prevTop;

  /// Top of the selected 295×87 card; its label sits 30px lower.
  final double cardTop;

  /// Top of the unselected item below the card.
  final double nextTop;
  final double cardLeft;
  final double textLeft;

  /// Left of the 24px trailing icon inside the card (top = cardTop + 32).
  final double trailingLeft;

  static const double cardWidth = 295;
  static const double cardHeight = 87;
}

/// The vertical selection wheel of the Category and Send frames: the focused
/// item in a white rounded card (radius 17, #D9D9D9 border) with a trailing
/// icon, its neighbours in grey above and below. Drag vertically (or tap a
/// neighbour) to move; the list is circular. [trailingKey] lets the tutorial
/// point at the card's action.
class DesignWheel extends StatefulWidget {
  const DesignWheel({
    super.key,
    required this.scale,
    required this.geometry,
    required this.items,
    required this.index,
    required this.onChanged,
    this.onCardTap,
    this.trailing,
    this.onTrailingTap,
    this.cardKey,
    this.trailingKey,
  });

  final double scale;
  final WheelGeometry geometry;
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onCardTap;
  final Widget? Function(int index)? trailing;
  final ValueChanged<int>? onTrailingTap;
  final Key? cardKey;
  final Key? trailingKey;

  /// The design-pixel band the wheel occupies (a little above prev to a little
  /// below next), so the whole band is draggable.
  static double top(WheelGeometry g) => g.prevTop - 30;
  static double bottom(WheelGeometry g) => g.nextTop + 55;

  @override
  State<DesignWheel> createState() => _DesignWheelState();
}

class _DesignWheelState extends State<DesignWheel> {
  double _drag = 0;
  int _direction = 1; // +1 moving down the list, -1 up — drives the slide.

  int get _n => widget.items.length;
  int _wrap(int i) => ((i % _n) + _n) % _n;

  void _step(int delta) {
    if (_n < 2) return;
    setState(() => _direction = delta);
    widget.onChanged(_wrap(widget.index + delta));
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.geometry;
    final s = widget.scale;
    final origin = DesignWheel.top(g);
    double y(double designTop) => (designTop - origin) * s;

    final showPrev = _n >= 3;
    final showNext = _n >= 2;
    final i = widget.index;

    Widget slot(String text, int key, TextStyle style) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        // Left-aligned like the Figma (the default layout centres).
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: Offset(0, 0.35 * _direction), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: Text(text, key: ValueKey('$key-$text'), maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
      );
    }

    final grey = BType.elms(20 * s, weight: BType.medium, color: AppColors.wheelGrey);
    final selected = BType.elms(20 * s, weight: BType.regular, color: Colors.black);
    final trailing = widget.trailing?.call(i);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _drag = 0,
      onVerticalDragUpdate: (d) {
        _drag += d.delta.dy;
        final threshold = 44 * s;
        if (_drag <= -threshold) {
          _drag = 0;
          _step(1);
        } else if (_drag >= threshold) {
          _drag = 0;
          _step(-1);
        }
      },
      child: Stack(clipBehavior: Clip.none, children: [
        if (showPrev)
          Positioned(
            left: g.textLeft * s, top: y(g.prevTop), right: 60 * s,
            child: GestureDetector(onTap: () => _step(-1), child: slot(widget.items[_wrap(i - 1)], _wrap(i - 1), grey)),
          ),
        Positioned(
          left: g.cardLeft * s, top: y(g.cardTop),
          width: WheelGeometry.cardWidth * s, height: WheelGeometry.cardHeight * s,
          child: GestureDetector(
            key: widget.cardKey,
            behavior: HitTestBehavior.opaque,
            onTap: widget.onCardTap == null ? null : () => widget.onCardTap!(i),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17 * s),
                border: Border.all(color: AppColors.cardBorder, width: 1),
                boxShadow: const [BoxShadow(color: Colors.white, blurRadius: 4)],
              ),
            ),
          ),
        ),
        Positioned(
          left: g.textLeft * s, top: y(g.cardTop + 30), right: (420 - g.trailingLeft + 8) * s,
          child: IgnorePointer(child: slot(widget.items[i], i, selected)),
        ),
        if (trailing != null)
          Positioned(
            left: (g.trailingLeft - 12) * s, top: y(g.cardTop + 32 - 12),
            width: 48 * s, height: 48 * s,
            child: GestureDetector(
              key: widget.trailingKey,
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTrailingTap == null ? null : () => widget.onTrailingTap!(i),
              child: Center(child: SizedBox(width: 24 * s, height: 24 * s, child: trailing)),
            ),
          ),
        if (showNext)
          Positioned(
            left: g.textLeft * s, top: y(g.nextTop), right: 60 * s,
            child: GestureDetector(onTap: () => _step(1), child: slot(widget.items[_wrap(i + 1)], _wrap(i + 1), grey)),
          ),
      ]),
    );
  }
}
