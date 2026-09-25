import 'package:flutter/material.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/design/type.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tour/tour_controller.dart';
import 'widgets/avatars.dart';

/// Menu — pixel-perfect to the Figma Menu frame (621:115).
///
/// The settings gear (62, 85) opens Settings; the giver's photo (318, 76, ⌀48)
/// can be changed by tapping it. "Bahasha" heads a swipeable carousel of
/// offering cards: the focused card is 296×459 (radius 14, white border) with
/// a white plus-circle; the next card peeks in at 266×412. Tapping a card
/// ("…into the store house") returns to the keypad to give.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const _cards = ['assets/menu/card_main.jpg', 'assets/menu/card_side.jpg'];

  /// The next card's centre is 289px right of the focused one (499 − 210).
  final _pc = PageController(viewportFraction: 289 / 420);

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _give() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PixelCanvas(
        background: Colors.white,
        fit: true,
        builder: (context, px) => [
          px.at(62 - 12, 85 - 12, width: 48, height: 48, child: Semantics(
            button: true,
            label: 'Settings',
            child: GestureDetector(
              key: TourKeys.menuSettings,
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: Center(child: DesignIcon('settings', scale: px.scale, tint: false)),
            ),
          )),
          px.at(318, 76, width: 48, height: 48, child: const UserAvatar(editable: true)),

          px.text(0, 205, 'Bahasha', size: 24, weight: BType.light, color: Colors.black,
              width: 420, align: TextAlign.center, fontFamily: BType.family, height: null),

          px.at(0, 293, width: 420, height: 459, child: PageView.builder(
            controller: _pc,
            padEnds: true,
            itemCount: _cards.length,
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _pc,
              builder: (context, child) {
                final page = _pc.hasClients && _pc.position.haveDimensions ? (_pc.page ?? 0) : 0.0;
                // 459 → 412 (and 296 → 266): the peeking card is ~0.9×.
                final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
                final scale = 412 / 459 + (1 - 412 / 459) * t;
                return Transform.scale(scale: scale, child: child);
              },
              // The 296-wide card is a little wider than its 289 page slot
              // (the Figma's 8px gap comes from the 0.9× neighbour), so let
              // it overflow the slot rather than be squeezed.
              child: OverflowBox(
                maxWidth: 296 * px.scale, minWidth: 296 * px.scale,
                maxHeight: 459 * px.scale, minHeight: 459 * px.scale,
                child: _Card(asset: _cards[i], scale: px.scale, onTap: _give),
              ),
            ),
          )),

          px.text(0, 776, '...into the store house', size: 16, weight: BType.light, color: Colors.black,
              width: 420, align: TextAlign.center, fontFamily: BType.family, height: null),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.asset, required this.scale, required this.onTap});
  final String asset;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Give',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14 * scale),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14 * scale),
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(asset, fit: BoxFit.cover),
              // Plus-circle: centred, top 692 in the frame = 399 into the card.
              Positioned(
                left: (148 - 12) * scale, top: 399 * scale,
                child: DesignIcon('plus_circle', scale: scale, tint: false),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
