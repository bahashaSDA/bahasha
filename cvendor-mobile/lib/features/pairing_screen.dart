import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/hub_session.dart';
import '../theme.dart';

/// One-time hub pairing. A deacon enters the API key their treasurer/admin
/// issued (provisioned by scripts/provision-hub.ts). The key is validated for
/// shape and stored in the secure keystore; from then on the hub goes straight
/// to the dashboard on launch.
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
      backgroundColor: HubColors.panelGreen,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: <Widget>[
            const Icon(Icons.hub_outlined, size: 56, color: HubColors.indigo),
            const SizedBox(height: 20),
            const Text('Set up your Church Hub',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: HubColors.ink)),
            const SizedBox(height: 8),
            const Text(
              'This device becomes the collection point for your church. Enter the '
              'hub key your treasurer gave you to begin receiving contributions.',
              style: TextStyle(fontSize: 15, color: HubColors.inkMuted, height: 1.4),
            ),
            const SizedBox(height: 32),
            _field(_church, 'Church name (optional)', 'e.g. Zetech University SDA'),
            const SizedBox(height: 16),
            _field(_key, 'Hub key', 'bhk_…', mono: true),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: HubColors.danger)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _saving ? null : _pair,
                style: FilledButton.styleFrom(
                  backgroundColor: HubColors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Pair hub', style: TextStyle(fontSize: 17, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint, {bool mono = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 14, color: HubColors.inkMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          style: TextStyle(fontFamily: mono ? 'monospace' : null, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
