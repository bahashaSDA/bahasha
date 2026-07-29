import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/pixel_canvas.dart';
import '../application/basket_controller.dart';
import '../domain/contribution_category.dart';
import 'widgets/offerings_header.dart';

/// The amount screen — pixel-perfect to the Figma basket frame (node 1:3). The
/// chosen fruit sits in the offertory basket, "How much ... are you giving?"
/// heads the screen, and the giver types an amount on the numeric keyboard.
/// Confirming adds this giving type to the basket and returns home.
class CategoryAmountScreen extends ConsumerStatefulWidget {
  const CategoryAmountScreen({super.key, required this.category});

  final ContributionCategory category;

  @override
  ConsumerState<CategoryAmountScreen> createState() => _CategoryAmountScreenState();
}

class _CategoryAmountScreenState extends ConsumerState<CategoryAmountScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(basketProvider).amountFor(widget.category.code);
    _controller = TextEditingController(text: existing > 0 ? existing.toString() : '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = int.tryParse(_controller.text.trim()) ?? 0;
    ref.read(basketProvider.notifier).setAmount(widget.category.code, amount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: PixelCanvas(
        background: Colors.white,
        builder: (context, px) => [
          ...offeringsHeader(context, px),

          px.text(0, 172, 'How much ${c.giveLabel} are you giving?',
              size: 20, weight: FontWeight.w300, color: Colors.black,
              width: 420, align: TextAlign.center, fontFamily: 'Inter'),

          // The chosen fruit, in the offertory basket.
          px.at(90, 250, width: 240, height: 240,
              child: Image.asset(c.asset, fit: BoxFit.contain)),

          // Amount entry — the numeric keyboard opens automatically, matching
          // the design. Pressing done adds it to the basket.
          px.at(0, 600, width: 420, child: Center(
            child: SizedBox(
              width: 300 * px.scale,
              child: TextField(
                controller: _controller,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirm(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: const Color(0xFF008805),
                style: TextStyle(
                  fontFamily: 'Inter', fontWeight: FontWeight.w300,
                  fontSize: 28 * px.scale, color: Colors.black,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Enter your amount',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w300,
                    fontSize: 20 * px.scale, color: const Color(0x80000000),
                  ),
                ),
              ),
            ),
          )),

          // A clear confirm affordance in addition to the keyboard's done key.
          px.at(0, 690, width: 420, child: Center(child: _ConfirmPill(onTap: _confirm))),
        ],
      ),
    );
  }
}

class _ConfirmPill extends StatelessWidget {
  const _ConfirmPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 420;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32 * scale, vertical: 18 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(62 * scale),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 3.5, offset: Offset(0, 1))],
        ),
        child: Text('Add to basket',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400,
                fontSize: 16 * scale, color: const Color(0xFF008805))),
      ),
    );
  }
}
