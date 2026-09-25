import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design/type.dart';

/// The large centred figure (Elms Sans ExtraLight 40): "0.0" before anything
/// is typed, as in the Figma Home frame, then whole shillings ("300",
/// "1,500").
class AmountText extends StatelessWidget {
  const AmountText({super.key, required this.amount, required this.scale});

  final int amount;
  final double scale;

  static final _fmt = NumberFormat('#,###', 'en_US');

  static String label(int amount) => amount <= 0 ? '0.0' : _fmt.format(amount);

  @override
  Widget build(BuildContext context) {
    // Same 0.08em glyph offset correction as Px.text (see pixel_canvas.dart).
    return Transform.translate(
      offset: Offset(0, -40 * 0.08 * scale),
      child: Text(
        label(amount),
        textAlign: TextAlign.center,
        maxLines: 1,
        style: BType.elms(40 * scale, weight: BType.extraLight),
      ),
    );
  }
}
