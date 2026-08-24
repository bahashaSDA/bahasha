import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/providers.dart';
import '../application/basket_controller.dart';
import '../domain/contribution_category.dart';
import 'category_amount_screen.dart';
import 'thank_you_screen.dart';
import 'widgets/offerings_header.dart';

/// The offertory basket / checkout — pixel-perfect to the Figma frame
/// (node 12:2). The chosen fruits collect in the basket, the running total shows
/// in green, and each selected giving type appears as a thumbnail that animates
/// in (the "fruits add to the basket" motion). "Give contribution" signs and
/// queues the whole basket as one contribution, then shows the thank-you screen.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> with SingleTickerProviderStateMixin {
  static final _money = NumberFormat('#,###', 'en_US');
  late final AnimationController _anim;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(basketProvider);
    final categories = ref.watch(categoriesProvider);
    final selected = <ContributionCategory>[
      for (final c in categories) if (basket.isSelected(c.code)) c,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: PixelCanvas(
        background: Colors.white,
        scrollable: true,
        contentHeight: 912,
        builder: (context, px) => [
          ...offeringsHeader(context, px),

          px.text(0, 172, 'My offertory basket', size: 20, weight: FontWeight.w300,
              color: Colors.black, width: 420, align: TextAlign.center, fontFamily: 'Inter'),

          // The offertory basket (the designer's real basket photo) with a
          // gentle pop. The fruits you actually chose are named below.
          px.at(56.5, 232, width: 307, height: 307, child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(
              CurvedAnimation(parent: _anim, curve: Curves.easeOutBack)),
            child: Image.asset('assets/baskets/basket_full.png', fit: BoxFit.contain),
          )),

          px.text(0, 569, 'KES ${_money.format(basket.total)}', size: 20, weight: FontWeight.w300,
              color: const Color(0xFF008805), width: 420, align: TextAlign.center, fontFamily: 'Inter'),

          px.text(0, 604, "You're giving", size: 13, weight: FontWeight.w400,
              color: const Color(0xFF8A8A93), width: 420, align: TextAlign.center, fontFamily: 'Inter'),

          // Chosen giving types — each drops into the basket (staggered).
          px.at(0, 636, width: 420, height: 150, child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16 * px.scale),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < selected.length; i++)
                  _thumb(px, selected[i], basket.amountFor(selected[i].code), i, selected.length),
              ]),
            ),
          )),

          px.at(0, 805, width: 420, child: Center(child: _GivePill(
            busy: _sending,
            onTap: _sending ? null : () => _give(selected),
          ))),
        ],
      ),
    );
  }

  Widget _thumb(Px px, ContributionCategory c, int amount, int index, int total) {
    final start = total <= 1 ? 0.0 : (index / total) * 0.5;
    final anim = CurvedAnimation(parent: _anim, curve: Interval(start, 1, curve: Curves.easeOutBack));
    return SizedBox(
      width: 124 * px.scale,
      child: FadeTransition(
        opacity: _anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.4, end: 1).animate(anim),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              // Tap the fruit → a small popup right here (add more / cancel).
              GestureDetector(
                onTapDown: (d) => _thumbPopup(c, d.globalPosition),
                child: SizedBox(width: 100 * px.scale, height: 100 * px.scale,
                    child: Image.asset(c.asset, fit: BoxFit.contain)),
              ),
              // Minus on the left removes this offering.
              Positioned(left: -6 * px.scale, top: 36 * px.scale,
                  child: _roundBtn(px, Icons.remove, () => _removeOffering(c))),
              // Plus on the right adds more to it.
              Positioned(right: -6 * px.scale, top: 36 * px.scale,
                  child: _roundBtn(px, Icons.add, () => _editAmount(c))),
            ]),
            SizedBox(height: 4 * px.scale),
            Text(c.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12 * px.scale, color: Colors.black)),
            Text('KES ${_money.format(amount)}', textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 11 * px.scale, color: const Color(0xFF008805))),
          ]),
        ),
      ),
    );
  }

  Widget _roundBtn(Px px, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26 * px.scale, height: 26 * px.scale,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3)],
        ),
        child: Icon(icon, size: 17 * px.scale, color: const Color(0xFF008805)),
      ),
    );
  }

  void _editAmount(ContributionCategory c) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryAmountScreen(category: c)));
  }

  void _removeOffering(ContributionCategory c) {
    ref.read(basketProvider.notifier).remove(c.code);
    if (ref.read(basketProvider).isEmpty && mounted) Navigator.of(context).pop();
  }

  Future<void> _thumbPopup(ContributionCategory c, Offset pos) async {
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: const [
        PopupMenuItem(value: 'add', height: 40, child: Row(children: [
          Icon(Icons.add, size: 18, color: Color(0xFF008805)), SizedBox(width: 8),
          Text('Add more', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
        ])),
        PopupMenuItem(value: 'cancel', height: 40, child: Row(children: [
          Icon(Icons.close, size: 18, color: Color(0xFFE03131)), SizedBox(width: 8),
          Text('Cancel offering', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
        ])),
      ],
    );
    if (choice == 'add') _editAmount(c);
    if (choice == 'cancel') _removeOffering(c);
  }

  Future<void> _give(List<ContributionCategory> selected) async {
    final basket = ref.read(basketProvider);
    if (basket.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _sending = true);
    try {
      final user = await ref.read(localDatabaseProvider).currentUser();
      if (user == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Please complete registration first')));
        setState(() => _sending = false);
        return;
      }
      await ref.read(contributionRepositoryProvider).createSigned(
            allocations: Map<String, int>.from(basket.amounts),
            user: user,
          );
      ref.read(basketProvider.notifier).clear();
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => const ThankYouScreen()));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not give: $e')));
      setState(() => _sending = false);
    }
  }
}

class _GivePill extends StatelessWidget {
  const _GivePill({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback? onTap;

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
        child: busy
            ? SizedBox(width: 18 * scale, height: 18 * scale,
                child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF008805)))
            : Text('Give contribution',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400,
                    fontSize: 16 * scale, color: const Color(0xFF008805))),
      ),
    );
  }
}
