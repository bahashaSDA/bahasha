import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/contribution_repository.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/type.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../contribution/presentation/home_screen.dart' show designSnack;

/// First-time welcome + registration, in the keypad/wheel design language:
/// white, Elms Sans, the centred title, the Settings pill, inputs drawn as
/// the design's selected card (white, radius 17, #D9D9D9, blue when focused)
/// and the blue "Continue" text action with the paper plane, as on Send.
///
/// We collect only what the system can't work out on its own: the giver's
/// name, phone, and the church they belong to (their HOME church). Whether a
/// given offering counts as a member or a visitor is decided automatically at
/// giving time by comparing this home church with the church of the CVendor
/// hub they hand to — so there is no "status" question here. Nothing goes
/// online: the backend learns this giver through the hub over Bluetooth.
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
  final _church = TextEditingController();
  final _churchFocus = FocusNode();
  bool _submitting = false;

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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          designSnack(context, 'Could not save your details. Please try again.', color: AppColors.red),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = size.width / 420;
    // Short phones: less air above the title so the form fits without scrolling.
    final top = size.height / s < 800 ? 48.0 : 110.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                // Same 62px side margins as Settings: fields are 296 wide,
                // the width of the design's selected-wheel card.
                padding: EdgeInsets.fromLTRB(62 * s, top * s, 62 * s, 24 * s),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Welcome to Bahasha', textAlign: TextAlign.center, style: BType.elms(24 * s)),
                  SizedBox(height: 18 * s),
                  // The Settings "Bahasha" pill (#F5F5F5, radius 29, padding 10).
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
                      decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(29 * s)),
                      child: Text('Only asked once', style: BType.elms(16 * s)),
                    ),
                  ),
                  SizedBox(height: 22 * s),
                  Text(
                    'Give to your church with your mobile data off. Your offering goes to the church over Bluetooth.',
                    textAlign: TextAlign.center,
                    style: BType.elms(16 * s, color: AppColors.wheelGrey, height: 1.4),
                  ),
                  SizedBox(height: 44 * s),

                  _label('Full name', s),
                  _field(s,
                      controller: _name,
                      hint: 'e.g. Grace Wanjiru',
                      keyboard: TextInputType.name,
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null),
                  SizedBox(height: 22 * s),

                  _label('Phone number', s),
                  _field(s,
                      controller: _phone,
                      hint: '07XX XXX XXX',
                      keyboard: TextInputType.phone,
                      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                      validator: _validatePhone),
                  SizedBox(height: 22 * s),

                  _label('Church you belong to', s),
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
                      cursorColor: AppColors.blue,
                      style: BType.elms(18 * s),
                      decoration: _decoration('e.g. Zetech University', s),
                    ),
                    optionsViewBuilder: (context, onSelected, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          margin: EdgeInsets.only(top: 6 * s),
                          constraints: BoxConstraints(maxHeight: 240 * s, maxWidth: 296 * s),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17 * s),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17 * s),
                            child: ListView(
                              padding: EdgeInsets.symmetric(vertical: 6 * s),
                              shrinkWrap: true,
                              children: [
                                for (final o in options)
                                  InkWell(
                                    onTap: () => onSelected(o),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 12 * s),
                                      child: Text(o, style: BType.elms(16 * s)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            // The design's text action, as on Send: "Continue" (Elms Sans
            // Light 24, blue) at x 89 with the paper plane at x 304.
            Semantics(
              button: true,
              label: 'Continue',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _submitting ? null : _submit,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(89 * s, 14 * s, (420 - 304 - 36) * s, 10 * s),
                  child: Row(children: [
                    Text(_submitting ? 'Saving…' : 'Continue', style: BType.elms(24 * s, color: AppColors.blue)),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _submitting ? 0.35 : 1,
                      child: DesignIcon('send', scale: s, size: 36, tint: false),
                    ),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 14 * s),
              child: Text('© 2026 Bahasha', style: BType.elms(13 * s, color: AppColors.wheelGrey)),
            ),
          ]),
        ),
      ),
    );
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
    // Same rule the backend applies (it must accept this number later).
    return ContributionRepository.normalizeMsisdn(v) != null ? null : 'Enter a valid Kenyan mobile number';
  }

  Widget _label(String text, double s) => Padding(
        padding: EdgeInsets.only(bottom: 10 * s),
        child: Text(text, style: BType.elms(16 * s)),
      );

  Widget _field(
    double s, {
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: capitalization,
      inputFormatters: formatters,
      validator: validator,
      cursorColor: AppColors.blue,
      style: BType.elms(18 * s),
      decoration: _decoration(hint, s),
    );
  }

  /// The design's card: white, radius 17, #D9D9D9 border; blue when focused.
  InputDecoration _decoration(String hint, double s) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(17 * s),
          borderSide: BorderSide(color: c, width: 1),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: BType.elms(18 * s, color: AppColors.placeholder),
      errorStyle: BType.elms(14 * s, color: AppColors.red),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 20 * s),
      border: border(AppColors.cardBorder),
      enabledBorder: border(AppColors.cardBorder),
      focusedBorder: border(AppColors.blue),
      errorBorder: border(AppColors.red),
      focusedErrorBorder: border(AppColors.red),
    );
  }
}
