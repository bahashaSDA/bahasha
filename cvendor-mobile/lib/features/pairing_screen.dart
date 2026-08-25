import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/hub_session.dart';
import '../theme.dart';

/// One-time hub pairing, in the offertory look: a deacon enters the API key the
/// treasurer shared (from the dashboard). The key is validated and stored in the
/// secure keystore; from then on the hub opens straight to the dashboard.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _key = TextEditingController();
  final _church = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _key.dispose();
    _church.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final key = _key.text.trim();
    if (!HubSession.isWellFormedKey(key)) {
      setState(() => _error = 'That does not look like a hub key (bhk_…).');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(hubSessionProvider).pair(
          apiKey: key,
          churchName: _church.text.trim().isEmpty ? 'Your church' : _church.text.trim(),
        );
    ref.invalidate(isPairedProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HubColors.surface,
      body: FruitBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
            children: <Widget>[
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0x1A008805),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.sensors, size: 34, color: HubColors.green),
              ),
              const SizedBox(height: 24),
              const Text('Set up your Church Hub',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w600, color: HubColors.ink)),
              const SizedBox(height: 10),
              const Text(
                'This device becomes the collection point for your church. Enter the '
                'hub key your treasurer shared to begin receiving offerings over Bluetooth.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: HubColors.inkMuted, height: 1.45),
              ),
              const SizedBox(height: 32),
              _label('Church name (optional)'),
              _field(_church, 'e.g. Zetech University SDA Church'),
              const SizedBox(height: 18),
              _label('Hub key'),
              _field(_key, 'bhk_…', mono: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontFamily: 'Inter', color: HubColors.danger)),
              ],
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _saving ? null : _pair,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: HubColors.green, borderRadius: BorderRadius.circular(62)),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Pair hub',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text('© 2026 Bahasha',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0x73000000)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: HubColors.ink)),
      );

  Widget _field(TextEditingController c, String hint, {bool mono = false}) => TextField(
        controller: c,
        style: TextStyle(fontFamily: mono ? 'monospace' : 'Inter', fontSize: 16, color: HubColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Inter', color: Color(0x80000000)),
          filled: true,
          fillColor: const Color(0xFFF5F5F7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: HubColors.green, width: 1.5),
          ),
        ),
      );
}
