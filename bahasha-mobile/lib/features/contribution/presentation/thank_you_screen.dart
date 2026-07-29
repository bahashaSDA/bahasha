import 'package:flutter/material.dart';
import '../../../core/design/pixel_canvas.dart';
import 'widgets/offerings_header.dart';

/// The thank-you screen — pixel-perfect to the Figma frame (node 14:135): a
/// blessing, hands holding the full offertory basket, and a "Give again" action
/// that returns home for a fresh basket. The E-receipts row from the Figma is
/// intentionally omitted per product direction.
class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PixelCanvas(
        background: Colors.white,
        scrollable: true,
        contentHeight: 912,
        builder: (context, px) => [
          ...offeringsHeader(context, px),

          px.text(66, 172, 'Dearly beloved of the Lord, be blessed.',
              size: 20, weight: FontWeight.w300, color: Colors.black, width: 311,
              height: 1.3, fontFamily: 'Inter'),

          px.at(0.5, 252, width: 419, height: 419,
              child: Image.asset('assets/baskets/basket_hands.png', fit: BoxFit.contain)),

          px.at(0, 805, width: 420, child: Center(child: _GiveAgainPill(
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ))),
        ],
      ),
    );
  }
}

class _GiveAgainPill extends StatelessWidget {
  const _GiveAgainPill({required this.onTap});
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
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Give again',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400,
                  fontSize: 16 * scale, color: const Color(0xFF008805))),
          SizedBox(width: 10 * scale),
          Icon(Icons.refresh, size: 17 * scale, color: const Color(0xFF008805)),
        ]),
      ),
    );
  }
}
