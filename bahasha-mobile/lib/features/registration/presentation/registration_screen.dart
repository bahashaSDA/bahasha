import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

/// First-time welcome + registration — one screen, no scrolling. We collect only
/// what the system can't work out on its own: the giver's name, phone, and the
/// church they belong to (their HOME church). Whether a given offering counts as
/// a member or a visitor is decided automatically at giving time by comparing
/// this home church with the church of the CVendor hub they hand to (known over
/// Bluetooth) — so there is no "status" question here. New givers are secret by
/// default; that can be changed later in the menu.
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
  bool _submitting = false;

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
          const SnackBar(content: Text('Please choose the church you belong to')),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(registrationRepositoryProvider).registerLocally(
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            churchId: _churchId!, // the giver's home church
            membershipStatus: 'member', // auto-reclassified per giving vs hub church
            visibility: 'secret', // secret by default
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: 64,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (final f in _welcomeFruits)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: SizedBox(width: 54, height: 54, child: Image.asset(f, fit: BoxFit.contain)),
                      ),
                  ]),
                ),
                const SizedBox(height: 18),
                const Text('Welcome to Bahasha',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w300, fontSize: 27, color: _ink)),
                const SizedBox(height: 8),
                const Text(
                  'Give to your church effortlessly — even with mobile data off. '
                  'This is only asked once.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: _grey, height: 1.4),
                ),
                const SizedBox(height: 26),

                _label('Full name'),
                _field(controller: _name, hint: 'e.g. Grace Wanjiru', keyboard: TextInputType.name,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null),
                const SizedBox(height: 16),

                _label('Phone number'),
                _field(controller: _phone, hint: '07XX XXX XXX', keyboard: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                    validator: _validatePhone),
                const SizedBox(height: 16),

                _label('Church you belong to'),
                DropdownButtonFormField<String>(
                  initialValue: _churchId,
                  items: _fallbackChurches
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontFamily: 'Inter'))))
                      .toList(),
                  onChanged: (v) => setState(() => _churchId = v),
                  decoration: _decoration('Choose your home church'),
                  isExpanded: true,
                ),

                const Spacer(),
                GestureDetector(
                  onTap: _submitting ? null : _submit,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(62)),
                    child: _submitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Continue',
                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(child: Text('© 2026 Bahasha',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0x73000000)))),
              ],
            ),
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
        padding: const EdgeInsets.only(bottom: 7),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _green, width: 1.5)),
      );
}
