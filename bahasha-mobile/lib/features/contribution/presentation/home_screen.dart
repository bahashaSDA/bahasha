import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/providers.dart';
import '../application/basket_controller.dart';
import '../domain/contribution_category.dart';
import 'category_amount_screen.dart';
import 'checkout_screen.dart';
import 'widgets/offerings_header.dart';

/// The Bahasha home / offertory screen — pixel-perfect to the new Figma
/// (node 6:20). A two-column grid of fruit tiles, each a giving type; choosing a
/// fruit opens its amount screen and adds it to the offertory basket. A floating
/// "My offertory basket" pill opens the checkout.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Per-tile geometry, in seed order, straight from Figma: image
  // (left, top, size) then label (left, top).
  static const List<_Tile> _tiles = <_Tile>[
    _Tile(56.59, 241, 145.79, 110, 384), // tithe
    _Tile(246, 241, 143, 287, 384), // offering
    _Tile(66.65, 442, 124.67, 73, 568), // church budget
    _Tile(251.63, 442, 129.93, 264, 568), // camp offering
    _Tile(66.65, 628, 124.67, 78, 754), // camp budget
    _Tile(254.65, 628, 124.67, 289, 754), // mission
    _Tile(76.7, 819.96, 104.95, 75, 922), // development
    _Tile(262.05, 814, 110.95, 256, 922), // children ministry
    _Tile(77.7, 986.96, 104.95, 78, 1089), // women ministry
    _Tile(264.67, 987, 104.33, 265, 1089), // adventist men
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final basket = ref.watch(basketProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final firstName = (user?.fullName ?? '').trim().split(' ').first;

    return Scaffold(
      backgroundColor: Colors.white,
      body: PixelCanvas(
        background: Colors.white,
        scrollable: true,
        contentHeight: 1150,
        builder: (context, px) => [
          ...offeringsHeader(context, px),

          px.text(66, 172,
              firstName.isEmpty ? 'Hello, what will you give?' : 'Hello $firstName, what will you give?',
              size: 20, weight: FontWeight.w300, color: Colors.black, fontFamily: 'Inter'),

          for (var i = 0; i < categories.length && i < _tiles.length; i++)
            ..._tile(context, px, categories[i], _tiles[i], basket.isSelected(categories[i].code)),

          // Floating "My offertory basket" pill (centered).
          px.at(0, 813, width: 420, child: Center(
            child: _BasketPill(
              count: basket.amounts.length,
              onTap: () => _openBasket(context, ref),
            ),
          )),
        ],
      ),
    );
  }

  List<Widget> _tile(BuildContext context, Px px, ContributionCategory c, _Tile t, bool selected) {
    return [
      px.at(t.left, t.top, width: t.size, height: t.size, child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openAmount(context, c),
        child: Stack(children: [
          Positioned.fill(child: Image.asset(c.asset, fit: BoxFit.contain)),
          if (selected)
            Positioned(right: 0, top: 0, child: Container(
              padding: EdgeInsets.all(2 * px.scale),
              decoration: const BoxDecoration(color: Color(0xFF008805), shape: BoxShape.circle),
              child: Icon(Icons.check, size: 14 * px.scale, color: Colors.white),
            )),
        ]),
      )),
      px.text(t.labelLeft, t.labelTop, c.name, size: 16, weight: FontWeight.w400,
          color: Colors.black, fontFamily: 'Inter'),
    ];
  }

  Future<void> _openAmount(BuildContext context, ContributionCategory category) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryAmountScreen(category: category)),
    );
  }

  void _openBasket(BuildContext context, WidgetRef ref) {
    if (ref.read(basketProvider).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a fruit to add to your basket first')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  }
}

class _Tile {
  const _Tile(this.left, this.top, this.size, this.labelLeft, this.labelTop);
  final double left, top, size, labelLeft, labelTop;
}

/// The white "My offertory basket" pill with the designed shadow and green text.
class _BasketPill extends StatelessWidget {
  const _BasketPill({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 420;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32 * scale, vertical: 20 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(62 * scale),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 3.5, offset: Offset(0, 1))],
        ),
        child: Text(
          count > 0 ? 'My offertory basket ($count)' : 'My offertory basket',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16 * scale,
            color: const Color(0xFF008805),
          ),
        ),
      ),
    );
  }
}
