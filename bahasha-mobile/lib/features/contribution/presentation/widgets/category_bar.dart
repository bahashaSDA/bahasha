import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/contribution_category.dart';

/// One full-width category row, matching the Figma exactly: 80px tall, flat
/// cycle colour, a 24px left-anchored label at x=40, and a 24px +/- control at
/// the right (x=356 in the 420-wide frame ⇒ 40px inset). When the category has
/// an amount it shows the amount and a minus, mirroring the contribution state.
class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.category,
    required this.color,
    required this.amount,
    required this.onAdd,
    required this.onRemove,
  });

  final ContributionCategory category;
  final Color color;

  /// Whole shillings; 0 means not selected.
  final int amount;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  static const double height = 80;
  static const double _inset = 40; // Figma left/right padding
  static const double _icon = 24;

  bool get _selected => amount > 0;

  @override
  Widget build(BuildContext context) {
    // Selected rows show the entered amount; unselected show the category name.
    final label = _selected ? amount.toStringAsFixed(2) : category.name;

    return Semantics(
      button: true,
      label: '${category.name}, ${_selected ? '$amount shillings selected' : 'not selected'}',
      child: Material(
        color: color,
        child: InkWell(
          onTap: _selected ? onRemove : onAdd,
          splashColor: Colors.black.withValues(alpha: 0.04),
          highlightColor: Colors.black.withValues(alpha: 0.03),
          child: SizedBox(
            height: height,
            child: Row(
              children: <Widget>[
                const SizedBox(width: _inset),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.rowLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                // The +/- affordance. AnimatedSwitcher gives the micro-interaction
                // of the icon morphing as the row toggles, per the "premium feel"
                // requirement — no page change, just a fluid state flip.
                IconButton(
                  onPressed: _selected ? onRemove : onAdd,
                  iconSize: _icon,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                    child: SvgPicture.asset(
                      _selected ? 'assets/icons/minus.svg' : 'assets/icons/plus.svg',
                      key: ValueKey<bool>(_selected),
                      width: _icon,
                      height: _icon,
                      colorFilter: const ColorFilter.mode(AppColors.ink, BlendMode.srcIn),
                    ),
                  ),
                ),
                const SizedBox(width: _inset - 10), // 44px hit target visually lands at inset
              ],
            ),
          ),
        ),
      ),
    );
  }
}
