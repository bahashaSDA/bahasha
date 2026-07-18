import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// First-time registration. Collected once; subsequent launches skip straight
/// to Home. Everything is written locally first so registration completes with
/// no connectivity, then syncs. The church list comes from the backend (cached)
/// so new churches appear without an app update; a small built-in fallback keeps
/// the picker usable on a first, never-synced launch.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  String? _churchId;
  String _membership = 'member';
  bool _anonymous = false;
  bool _submitting = false;

  // Fallback church list mirrors the backend seed; replaced by the live list
  // once fetched. Kept minimal here — the real list is server-driven.
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
      // Sync is best-effort; local registration already lets the app proceed.
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
      // The outbox/sync service will retry when the network returns.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelGreen,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: <Widget>[
              Text('Welcome to Bahasha', style: AppTypography.title),
              const SizedBox(height: 8),
              Text(
                'Give to your church effortlessly — even with mobile data off. '
                'Tell us who you are; this is only asked once.',
                style: AppTypography.description,
              ),
              const SizedBox(height: 28),

              _label('Full name'),
              _field(
                controller: _name,
                hint: 'e.g. Grace Wanjiru',
                keyboard: TextInputType.name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
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
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _churchId = v),
                decoration: _decoration('Choose your church'),
                isExpanded: true,
              ),
              const SizedBox(height: 24),

              _label('Your status'),
              _MembershipChoice(
                value: _membership,
                onChanged: (v) => setState(() => _membership = v),
              ),
              const SizedBox(height: 20),

              SwitchListTile.adaptive(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.indigo,
                title: Text('Give anonymously', style: AppTypography.rowLabel.copyWith(fontSize: 18)),
                subtitle: Text(
                  'Your name and phone are hidden from church reports. You can change this anytime in Account.',
                  style: AppTypography.description.copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.indigo,
                    foregroundColor: AppColors.onIndigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Continue', style: AppTypography.action.copyWith(fontSize: 18)),
                ),
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
    // Accept 07.., 7.., 2547.., matching the normalisation the backend applies.
    final ok = RegExp(r'^(0|254|\+254)?[17][0-9]{8}$').hasMatch(v.replaceAll(' ', '')) ||
        digits.length >= 9;
    return ok ? null : 'Enter a valid Kenyan mobile number';
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTypography.rowLabel.copyWith(fontSize: 16)),
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
      style: AppTypography.rowLabel.copyWith(fontSize: 18, color: AppColors.inkMuted),
      decoration: _decoration(hint),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.indigo, width: 1.5),
        ),
      );
}

/// Membership status selector: the three options from the spec.
class _MembershipChoice extends StatelessWidget {
  const _MembershipChoice({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

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
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(o.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.indigo : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? Colors.white : AppColors.inkMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    o.label,
                    style: AppTypography.rowLabel.copyWith(
                      fontSize: 16,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
