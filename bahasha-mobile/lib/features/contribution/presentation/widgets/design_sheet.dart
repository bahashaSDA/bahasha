import 'package:flutter/material.dart';
import '../../../../core/design/icon.dart';
import '../../../../core/design/type.dart';
import '../../../../core/theme/app_colors.dart';

/// The bottom card of the Vendor Card frame (692:440): a white 420×319 sheet,
/// top corners 24, a faint blue top shadow (0 −1 1 rgba(23,116,255,.25)), and
/// the red close "x" at (355, 37). Also used for the app's other small
/// dialogs (edit details, delete account, prayer info) so every pop-up speaks
/// the same visual language.
Future<T?> showDesignSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, double scale) builder,
  double designHeight = 319,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) {
      final scale = MediaQuery.of(ctx).size.width / 420;
      final inset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          constraints: BoxConstraints(minHeight: designHeight * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
            boxShadow: const [BoxShadow(color: AppColors.sheetShadow, offset: Offset(0, -1), blurRadius: 1)],
          ),
          child: SafeArea(
            top: false,
            child: Stack(children: [
              builder(ctx, scale),
              Positioned(
                left: (355 - 12) * scale, top: (37 - 12) * scale,
                width: 48 * scale, height: 48 * scale,
                child: Semantics(
                  button: true,
                  label: 'Close',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(ctx).maybePop(),
                    child: Center(child: DesignIcon('x_red', scale: scale, color: AppColors.red)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    },
  );
}

/// The Vendor Card body: a ⌀103 portrait at (158.5, 57) and a centred 231-wide
/// Elms Sans Light 20 introduction at top 195.
class PortraitMessage extends StatelessWidget {
  const PortraitMessage({super.key, required this.scale, required this.portrait, required this.message});

  final double scale;
  final Widget portrait;
  final String message;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      width: double.infinity,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 57 * s),
        SizedBox(width: 103 * s, height: 103 * s, child: ClipOval(child: portrait)),
        SizedBox(height: 35 * s),
        SizedBox(
          width: 231 * s,
          child: Text(message, textAlign: TextAlign.center, style: BType.elms(20 * s)),
        ),
        SizedBox(height: 40 * s),
      ]),
    );
  }
}

/// A plain Elms Sans text action, the way the design writes its actions
/// ("Send", "Download receipts", "Delete my account"): coloured text with an
/// optional trailing icon, no button chrome.
class TextAction extends StatelessWidget {
  const TextAction({super.key, required this.label, required this.onTap, required this.scale, this.color = AppColors.blue, this.size = 16});

  final String label;
  final VoidCallback? onTap;
  final double scale;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10 * scale),
        child: Text(label, style: BType.elms(size * scale, color: onTap == null ? AppColors.placeholder : color)),
      ),
    );
  }
}
