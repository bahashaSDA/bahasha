import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/design/type.dart';
import '../../../core/theme/app_colors.dart';
import '../../tour/tour_controller.dart';
import '../application/basket_controller.dart';
import '../domain/contribution_category.dart';
import 'menu_screen.dart';
import 'send_screen.dart';
import 'widgets/amount_text.dart';
import 'widgets/design_wheel.dart';

/// Home — pixel-perfect to the Figma Home frame (621:5) and, in place of the
/// keypad, the Category frame (621:54).
///
/// The centred title is the category being given to and the figure below it
/// is that category's amount. The keypad types whole shillings straight into
/// the basket; the capsule key opens the category wheel, where the arrow
/// selects. Every category keeps its own amount, so one gift can cover
/// several. The send icon (top right) reviews the basket on the Send screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Figma Category frame geometry (621:54).
  static const _wheel = WheelGeometry(
    prevTop: 535, cardTop: 593, nextTop: 712,
    cardLeft: 68, textLeft: 94, trailingLeft: 315,
  );

  int _focus = 0; // wheel position while picking

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final done = await ref.read(tourDoneProvider.future);
      if (!done && mounted) ref.read(tourProvider.notifier).start();
    });
  }

  List<ContributionCategory> get _order => wheelOrder(ref.read(categoriesProvider));

  void _openPicker() => ref.read(homePickingProvider.notifier).state = true;

  void _select(int index) {
    ref.read(currentCategoryProvider.notifier).state = _order[index].code;
    ref.read(homePickingProvider.notifier).state = false;
  }

  void _press(String code, int digit) {
    HapticFeedback.selectionClick();
    final basket = ref.read(basketProvider.notifier);
    basket.setAmount(code, KeypadInput.press(ref.read(basketProvider).amountFor(code), digit));
  }

  void _backspace(String code, {bool all = false}) {
    HapticFeedback.selectionClick();
    final current = ref.read(basketProvider).amountFor(code);
    ref.read(basketProvider.notifier).setAmount(code, all ? 0 : KeypadInput.backspace(current));
  }

  void _openSend() {
    if (ref.read(basketProvider).isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(designSnack(context, 'Enter an amount to give first'));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SendScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final picking = ref.watch(homePickingProvider);
    final basket = ref.watch(basketProvider);
    final order = wheelOrder(ref.watch(categoriesProvider));
    final currentCode = ref.watch(currentCategoryProvider);
    // Whoever opens the wheel (the capsule key or the guided tour), it opens
    // on the category currently being typed into.
    ref.listen<bool>(homePickingProvider, (was, now) {
      if (now && was != true) {
        final i = _order.indexWhere((c) => c.code == ref.read(currentCategoryProvider));
        setState(() => _focus = i < 0 ? 0 : i);
      }
    });
    final shown = picking
        ? order[_focus.clamp(0, order.length - 1)]
        : order.firstWhere((c) => c.code == currentCode, orElse: () => order.first);
    final amount = basket.amountFor(shown.code);

    return PopScope(
      canPop: !picking,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && picking) ref.read(homePickingProvider.notifier).state = false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: PixelCanvas(
          background: Colors.white,
          fit: true,
          builder: (context, px) => [
            // Menu (62, 85) — two lines, black.
            px.at(62 - 12, 85 - 12, width: 48, height: 48, child: _Tap(
              key: TourKeys.homeMenu,
              label: 'Menu',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MenuScreen())),
              child: DesignIcon('menu_lines', scale: px.scale, tint: false),
            )),
            // Send (339, 79) — the blue paper plane.
            px.at(339 - 6, 79 - 6, width: 48, height: 48, child: _Tap(
              key: TourKeys.homeSend,
              label: 'Review and send',
              onTap: _openSend,
              child: DesignIcon('send', scale: px.scale, size: 36, tint: false),
            )),

            // Title + amount (tour anchor spans both).
            px.at(60, 170, width: 300, height: 215, child: SizedBox(key: TourKeys.homeAmount)),
            px.text(0, 189, shown.name, size: 24, weight: BType.light, color: Colors.black,
                width: 420, align: TextAlign.center, fontFamily: BType.family, height: null),
            px.at(0, 315, width: 420, child: AmountText(amount: amount, scale: px.scale)),

            if (!picking) ..._keypad(px, shown.code) else ..._picker(px, order, basket),
          ],
        ),
      ),
    );
  }

  List<Widget> _keypad(Px px, String code) {
    // Glyph centres from the Figma text boxes, measured against the render.
    const cols = [98.5, 208.5, 320.5];
    const rows = [532.5, 634.5, 737.5, 840.5];
    Widget key(double cx, double cy, Widget child, VoidCallback onTap, {VoidCallback? onLongPress, String? label, Key? k}) {
      return px.at(cx - 52, cy - 48, width: 104, height: 96, child: _Tap(
        key: k, label: label, onTap: onTap, onLongPress: onLongPress, child: child,
      ));
    }

    // Figma: Dotum 36 (digit cap-height 24px). The Nanum Gothic substitute's
    // digits are ~8% taller, so 33.5 reproduces the designed glyph size.
    final digitStyle = BType.keypad(33.5 * px.scale, color: AppColors.keypadInk);
    return [
      px.at(40, 470, width: 340, height: 420, child: SizedBox(key: TourKeys.homeKeypad)),
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++)
          key(cols[c], rows[r], Text('${r * 3 + c + 1}', style: digitStyle),
              () => _press(code, r * 3 + c + 1), label: '${r * 3 + c + 1}'),
      key(cols[0], rows[3], Text('0', style: digitStyle), () => _press(code, 0), label: '0'),
      // The capsule key (Frame 1, 51×50 at 184, 813) opens the category wheel.
      key(209.5, 838, DesignIcon('key_down', scale: px.scale, width: 51, height: 50, tint: false),
          _openPicker, label: 'Choose category', k: TourKeys.homeCategory),
      // Backspace (Group 1, 28×19.64 at 306, 828); long-press clears.
      key(320, 837.8, DesignIcon('key_backspace', scale: px.scale, width: 28, height: 19.636, tint: false),
          () => _backspace(code), onLongPress: () => _backspace(code, all: true), label: 'Delete'),
    ];
  }

  List<Widget> _picker(Px px, List<ContributionCategory> order, BasketState basket) {
    final top = DesignWheel.top(_wheel);
    return [
      px.at(0, top, width: 420, height: DesignWheel.bottom(_wheel) - top, child: DesignWheel(
        scale: px.scale,
        geometry: _wheel,
        items: [for (final c in order) c.name],
        index: _focus.clamp(0, order.length - 1),
        onChanged: (i) => setState(() => _focus = i),
        onCardTap: _select,
        onTrailingTap: _select,
        cardKey: TourKeys.categoryCard,
        trailing: (_) => DesignIcon('arrow_right_circle_blue', scale: px.scale, tint: false),
      )),
      px.text(0, 830, 'scroll for more', size: 15, weight: BType.light, color: Colors.black,
          width: 420, align: TextAlign.center, fontFamily: BType.family),
      // Scroll capsule (19×30, top 858) steps to the next category.
      px.at(210 - 24, 858 - 9, width: 48, height: 48, child: _Tap(
        label: 'Next category',
        onTap: () => setState(() => _focus = (_focus + 1) % order.length),
        child: DesignIcon('scroll_down', scale: px.scale, width: 19, height: 30, tint: false),
      )),
    ];
  }
}

/// A transparent, generously sized hit area around a design glyph.
class _Tap extends StatelessWidget {
  const _Tap({super.key, required this.child, required this.onTap, this.onLongPress, this.label});
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Center(child: child),
      ),
    );
  }
}

/// A quiet snackbar in the design's type: white, Elms Sans, blue text.
SnackBar designSnack(BuildContext context, String message, {Color color = AppColors.blue}) {
  final s = MediaQuery.of(context).size.width / 420;
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    elevation: 0,
    backgroundColor: Colors.white,
    // Floats above the bottom action row (Send / Give again at y 818–888),
    // never over the button the message points to.
    margin: EdgeInsets.fromLTRB(32 * s, 0, 32 * s, 104 * s),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17 * s),
      side: const BorderSide(color: AppColors.cardBorder),
    ),
    content: Text(message, textAlign: TextAlign.center, style: BType.elms(16 * s, color: color)),
  );
}
