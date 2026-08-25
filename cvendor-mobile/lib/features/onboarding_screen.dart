import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

/// First-run walkthrough for the hub deacon: what the hub is, pairing, running
/// it during the service, and automatic upload. Shown once, in the offertory
/// look. [onDone] fires when finished or skipped.
class HubOnboardingScreen extends StatefulWidget {
  const HubOnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  static const _kSeen = 'cvendor.onboarding.seen.v1';

  static Future<bool> seen() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kSeen) ?? false;
  }

  static Future<void> markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSeen, true);
  }

  @override
  State<HubOnboardingScreen> createState() => _HubOnboardingScreenState();
}

class _HubOnboardingScreenState extends State<HubOnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _steps = <({IconData icon, String title, String body})>[
    (
      icon: Icons.sensors,
      title: 'This is your Church Hub',
      body: 'This phone becomes your church’s collection point — it receives offerings from members’ phones over Bluetooth.',
    ),
    (
      icon: Icons.vpn_key_outlined,
      title: 'Pair it once',
      body: 'Your treasurer generates a hub key on the dashboard and shares it with you. Paste it in to pair — you only do this once.',
    ),
    (
      icon: Icons.bluetooth_connected,
      title: 'During the service',
      body: 'Keep this screen open. It advertises over Bluetooth and receives each member’s offering as they give.',
    ),
    (
      icon: Icons.cloud_upload_outlined,
      title: 'Uploads happen automatically',
      body: 'Received offerings queue safely and upload to the church’s account. You’ll see the count and status live, even after a brief network drop.',
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
      backgroundColor: HubColors.surface,
      body: FruitBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                  child: TextButton(
                    onPressed: widget.onDone,
                    child: const Text('Skip', style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: HubColors.inkMuted)),
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
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 128, height: 128,
                          decoration: BoxDecoration(color: const Color(0x1A008805), borderRadius: BorderRadius.circular(36)),
                          child: Icon(s.icon, size: 60, color: HubColors.green),
                        ),
                        const SizedBox(height: 40),
                        Text(s.title, textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 26, color: HubColors.ink)),
                        const SizedBox(height: 14),
                        Text(s.body, textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF5A5A66), height: 1.5)),
                      ]),
                    );
                  },
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 22 : 8, height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? HubColors.green : const Color(0x33008805),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ]),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: HubColors.green, borderRadius: BorderRadius.circular(62)),
                    child: Text(_last ? 'Get started' : 'Next',
                        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
