import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

/// First-time welcome + registration, styled to match the offertory redesign:
/// white canvas, Inter face, offertory green. Collected once; later launches go
/// straight to Home. Written locally first so it completes offline, then syncs.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  static const _green = Color(0xFF008805);
  static const _ink = Colors.black;
  static const _grey = Color(0xFF6B6B76);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  String? _churchId;
  String _membership = 'member';
  bool _anonymous = false;
  bool _submitting = false;

  // The four welcome fruits (a taste of the offertory grid).
  static const _welcomeFruits = <String>[
    'assets/fruits/tithe.png', 'assets/fruits/offering.png',
    'assets/fruits/camp_budget.png', 'assets/fruits/mission.png',
  ];

  static const _fallbackChurches = <({String id, String name})>[
    (id: '00000000-0000-0000-0000-000000000001', name: 'Zetech University SDA Church'),
    (id: '00000000-0000-0000-0000-000000000002', name: 'Jomo Kenyatta University SDA Church'),
    (id: '00000000-0000-0000-0000-000000000003', name: 'Kenyatta University SDA Church'),
    (id: '00000000-0000-0000-0000-000000000004', name: 'KCA University SDA Church'),
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _churchId == null) {
      if (_churchId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose your church')),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = ref.read(registrationRepositoryProvider);
      await repo.registerLocally(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        churchId: _churchId!,
        membershipStatus: _membership,
        visibility: _anonymous ? 'secret' : 'open',
      );
      unawaited(_trySync());
      ref.invalidate(currentUserProvider);
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save registration: $e')),
        );
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _trySync() async {
    try {
      await ref.read(registrationRepositoryProvider).sync();
      ref.invalidate(currentUserProvider);
    } catch (_) {
      // The outbox/sync service retries when the network returns.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
            children: <Widget>[
              // Welcome fruit motif.
              SizedBox(
                height: 72,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final f in _welcomeFruits)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(width: 60, height: 60, child: Image.asset(f, fit: BoxFit.contain)),
                    ),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('Welcome to Bahasha',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w300, fontSize: 28, color: _ink)),
              const SizedBox(height: 10),
              const Text(
                'Give to your church effortlessly — even with mobile data off. '
                'Tell us who you are; this is only asked once.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: _grey, height: 1.4),
              ),
              const SizedBox(height: 28),

              _label('Full name'),
              _field(
                controller: _name,
                hint: 'e.g. Grace Wanjiru',
                keyboard: TextInputType.name,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),

              _label('Phone number'),
              _field(
                controller: _phone,
                hint: '07XX XXX XXX',
                keyboard: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                validator: _validatePhone,
              ),
              const SizedBox(height: 20),

              _label('Church'),
              DropdownButtonFormField<String>(
                initialValue: _churchId,
                items: _fallbackChurches
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontFamily: 'Inter'))))
                    .toList(),
                onChanged: (v) => setState(() => _churchId = v),
                decoration: _decoration('Choose your church'),
                isExpanded: true,
              ),
              const SizedBox(height: 24),

              _label('Your status'),
              _MembershipChoice(value: _membership, onChanged: (v) => setState(() => _membership = v)),
              const SizedBox(height: 12),

              SwitchListTile.adaptive(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
                contentPadding: EdgeInsets.zero,
                activeTrackColor: _green,
                title: const Text('Give secretly',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 17, color: _ink)),
                subtitle: const Text(
                  'Your name and phone are hidden from church reports. You can change this anytime in the menu.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: _grey, height: 1.35),
                ),
              ),
              const SizedBox(height: 24),

              // Green pill continue button (matches the offertory pills).
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(62),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continue',
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('Made by calemaley  ·  © 2026 Bahasha',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0x73000000))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    final ok = RegExp(r'^(0|254|\+254)?[17][0-9]{8}$').hasMatch(v.replaceAll(' ', '')) || digits.length >= 9;
    return ok ? null : 'Enter a valid Kenyan mobile number';
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 15, color: _ink)),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: validator,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: _ink),
      decoration: _decoration(hint),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Inter', color: Color(0x80000000)),
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      );
}

/// Membership status selector, in the offertory green.
class _MembershipChoice extends StatelessWidget {
  const _MembershipChoice({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _green = Color(0xFF008805);
  static const _options = <({String id, String label})>[
    (id: 'member', label: 'Member of this church'),
    (id: 'visitor', label: 'Visitor'),
    (id: 'other_church_member', label: 'Member of another church'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _options.map((o) {
        final selected = o.id == value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(o.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? _green : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? _green : const Color(0x1F000000)),
              ),
              child: Row(children: <Widget>[
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? Colors.white : const Color(0xFF9A9AAE), size: 22),
                const SizedBox(width: 12),
                Text(o.label,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: selected ? Colors.white : Colors.black)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}
