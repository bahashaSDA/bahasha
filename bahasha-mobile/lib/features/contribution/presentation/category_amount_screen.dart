import 'package:flutter/material.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/contribution_category.dart';

/// The category amount-entry screen — pixel-perfect to the Figma "Tithe" frame
/// (node 200:673). Panel-green background; the category title and description at
/// the top; a "type amount" field with a clear (×); and a custom 3×4 number pad
/// (1–9, *, 0, ⌫) at the exact Figma positions. Tapping digits builds the
/// amount; the arrow/back returns it to the basket.
class CategoryAmountScreen extends StatefulWidget {
  const CategoryAmountScreen({super.key, required this.category, this.initial = 0});

  final ContributionCategory category;
  final int initial;

  @override
  State<CategoryAmountScreen> createState() => _CategoryAmountScreenState();
}

class _CategoryAmountScreenState extends State<CategoryAmountScreen> {
  late String _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.initial > 0 ? '${widget.initial}' : '';
  }

  void _tapDigit(String d) {
    if (_amount.length >= 7) return;
    setState(() => _amount = _amount == '0' ? d : _amount + d);
  }

  void _backspace() {
    if (_amount.isEmpty) return;
    setState(() => _amount = _amount.substring(0, _amount.length - 1));
  }

  void _confirm() => Navigator.of(context).pop(int.tryParse(_amount) ?? 0);

  String _title() {
    switch (widget.category.code) {
      case 'tithe':
        return 'Tithe';
      case 'combined_offering':
        return 'Offering';
      default:
        return widget.category.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Number-pad glyph → (left, top) in design pixels, from the Figma.
    const keys = <(String, double, double)>[
      ('1', 78, 622), ('2', 204, 622), ('3', 336, 622),
      ('4', 75, 693), ('5', 203, 693), ('6', 336, 693),
      ('7', 76, 764), ('8', 205, 764), ('9', 336, 764),
      ('*', 78, 835), ('0', 203, 835),
    ];

    return Scaffold(
      backgroundColor: AppColors.panelGreen,
      body: PixelCanvas(
        background: AppColors.panelGreen,
        builder: (context, px) => [
          // Menu (back).
          px.at(356, 69, width: 24, height: 24, child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: DesignIcon('menu', scale: px.scale),
          )),

          // Title + description (charcoal, as in Figma).
          px.text(40, 222, _title(), size: 32, color: AppColors.inkMuted),
          px.text(40, 288, widget.category.description, size: 16, color: AppColors.inkMuted, width: 323, height: 1.3),

          // Amount field: typed value or the "type amount" placeholder.
          px.text(
            71, 491,
            _amount.isEmpty ? 'type amount' : _amount,
            size: 24,
            color: _amount.isEmpty ? Colors.black.withValues(alpha: 0.36) : Colors.black,
          ),
          // Backspace (×) at the right of the field — deletes the last digit.
          px.at(324, 488, width: 30, height: 30, child: GestureDetector(
            onTap: _backspace,
            child: DesignIcon('x', scale: px.scale, color: AppColors.ink),
          )),

          // Number pad digits/star.
          for (final (glyph, left, top) in keys)
            px.at(left, top, width: 40, height: 34, child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _tapDigit(glyph == '*' ? '' : glyph),
              child: Center(
                child: Text(
                  glyph,
                  style: TextStyle(
                    fontFamily: 'BahashaSans',
                    fontWeight: FontWeight.w300,
                    fontSize: 24 * px.scale,
                    color: Colors.black,
                  ),
                ),
              ),
            )),

          // Enter (⏎) at bottom right — saves the amount and returns to Home.
          px.at(332, 830, width: 34, height: 34, child: GestureDetector(
            onTap: _confirm,
            child: Center(child: DesignIcon('backspace', scale: px.scale, color: Colors.black)),
          )),
        ],
      ),
    );
  }
}
