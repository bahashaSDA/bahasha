import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/contribution_repository.dart';
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
  final _church = TextEditingController();
  final _churchFocus = FocusNode();
  bool _submitting = false;

  static const _welcomeFruits = <String>[
    'assets/fruits/tithe.png', 'assets/fruits/offering.png',
    'assets/fruits/camp_budget.png', 'assets/fruits/mission.png',
  ];

  // Suggestions for the church autocomplete. Anything typed that isn't here is
  // still accepted and normalised to end with "SDA Church".
  static const _churchSuggestions = <String>[
    'Zetech University SDA Church',
    'Jomo Kenyatta University (JKUAT) SDA Church',
    'Kenyatta University SDA Church',
    'KCA University SDA Church',
    'University of Nairobi SDA Church',
    'Maseno University SDA Church',
    'Moi University SDA Church',
    'Egerton University SDA Church',
    'Technical University of Kenya SDA Church',
    'Multimedia University SDA Church',
    'Strathmore University SDA Church',
    'Dedan Kimathi University SDA Church',
    'Maasai Mara University SDA Church',
    'Kabarak University SDA Church',
    'Mount Kenya University SDA Church',
  ];

  /// Case/space/punctuation-insensitive key for matching.
  static String _key(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Ensure a free-typed church name ends with "SDA Church" so records stay
  /// consistent (member/visitor matching is itself space/case-insensitive).
  static String _ensureSdaChurch(String raw) {
    final s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) return s;
    final lower = s.toLowerCase();
    if (lower.endsWith('sda church')) return s;
    if (lower.endsWith('church')) {
      final stem = s.substring(0, s.length - 'church'.length).trimRight();
      return lower.contains('sda') ? '$stem Church' : '$stem SDA Church';
    }
    if (lower.endsWith('sda')) return '$s Church';
    return '$s SDA Church';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _church.dispose();
    _churchFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(registrationRepositoryProvider).registerLocally(
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            churchId: _ensureSdaChurch(_church.text), // home church, normalised to "… SDA Church"
            membershipStatus: 'member', // auto-reclassified per giving vs hub church
            visibility: 'open', // give openly by default
          );
      // No network call: the backend learns this giver through the church's
      // CVendor hub over Bluetooth, the first time they give.
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
                RawAutocomplete<String>(
                  textEditingController: _church,
                  focusNode: _churchFocus,
                  optionsBuilder: (value) {
                    final q = _key(value.text);
                    if (q.isEmpty) return const Iterable<String>.empty();
                    return _churchSuggestions.where((c) => _key(c).contains(q));
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your church' : null,
                    onFieldSubmitted: (_) => onSubmit(),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: _ink),
                    decoration: _decoration('Start typing, e.g. Zetech University'),
                  ),
                  optionsViewBuilder: (context, onSelected, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 240, maxWidth: MediaQuery.of(context).size.width - 56),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            for (final o in options)
                              InkWell(
                                onTap: () => onSelected(o),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Text(o, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: _ink)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
    // Same rule the backend applies (it must accept this number later).
    return ContributionRepository.normalizeMsisdn(v) != null ? null : 'Enter a valid Kenyan mobile number';
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
