import 'package:flutter/material.dart';

/// The first-run walkthrough — a short, friendly tour of how giving works,
/// shown once on the very first open, in the offertory look (white, Inter,
/// offertory green). Calls [onDone] when the giver finishes or skips.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _green = Color(0xFF008805);
  final _pc = PageController();
  int _page = 0;

  static const _steps = <({String image, String title, String body})>[
    (
      image: 'assets/baskets/basket_hands.png',
      title: 'Welcome to Bahasha',
      body: 'Give to your church anytime — even with your mobile data off. It is simple, private, and quick.',
    ),
    (
      image: 'assets/fruits/tithe.png',
      title: 'Choose what you are giving',
      body: 'Every fruit is a giving type — tithe, offering, mission and more. Tap the ones you want to give to.',
    ),
    (
      image: 'assets/fruits/offering.png',
      title: 'Enter your amount',
      body: 'Type how much for each, and it drops into your offertory basket. Add as many as you like.',
    ),
    (
      image: 'assets/baskets/basket_full.png',
      title: 'Give at church',
      body: 'Open “My offertory basket”, tap Give contribution, and hold your phone near the church’s collection point — it sends securely over Bluetooth.',
    ),
    (
      image: 'assets/fruits/mission.png',
      title: 'History & privacy',
      body: 'Find your giving history and turn on “give secretly” anytime from the menu (top-left).',
    ),
  ];

  bool get _last => _page == _steps.length - 1;

  void _next() {
    if (_last) {
      widget.onDone();
    } else {
      _pc.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Skip',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Color(0xFF8A8A93))),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (context, i) {
                  final s = _steps[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 240, child: Image.asset(s.image, fit: BoxFit.contain)),
                        const SizedBox(height: 40),
                        Text(s.title, textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 26, color: Colors.black)),
                        const SizedBox(height: 14),
                        Text(s.body, textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF5A5A66), height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? _green : const Color(0x33008805),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: GestureDetector(
                onTap: _next,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(62)),
                  child: Text(_last ? 'Get started' : 'Next',
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
