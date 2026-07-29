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
///
/// Responsive: the header/title/fruit are placed on the 420-wide canvas, while
/// the amount field + confirm ride in a bottom bar padded by the keyboard inset
/// (MediaQuery.viewInsets.bottom), so the input is always visible just above the
/// keyboard regardless of the device's keyboard height.
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
    final width = MediaQuery.of(context).size.width;
    final scale = width / 420;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Top content on the exact design canvas.
          PixelCanvas(
            background: Colors.white,
            builder: (context, px) => [
              ...offeringsHeader(context, px),
              px.text(0, 172, 'How much ${c.giveLabel} are you giving?',
                  size: 20, weight: FontWeight.w300, color: Colors.black,
                  width: 420, align: TextAlign.center, fontFamily: 'Inter'),
              px.at(90, 250, width: 240, height: 240,
                  child: Image.asset(c.asset, fit: BoxFit.contain)),
            ],
          ),

          // Amount entry — floats just above the keyboard on any device.
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Padding(
              padding: EdgeInsets.only(bottom: keyboard),
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(24 * scale, 20 * scale, 24 * scale, 28 * scale),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
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
                      fontSize: 28 * scale, color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Enter your amount',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter', fontWeight: FontWeight.w300,
                        fontSize: 20 * scale, color: const Color(0x80000000),
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * scale),
                  _ConfirmPill(scale: scale, onTap: _confirm),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmPill extends StatelessWidget {
  const _ConfirmPill({required this.scale, required this.onTap});
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
