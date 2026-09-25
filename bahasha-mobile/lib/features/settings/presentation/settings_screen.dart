import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/data/local_database.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/design/type.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../contribution/application/basket_controller.dart';
import '../../contribution/presentation/home_screen.dart' show designSnack;
import '../../contribution/presentation/widgets/avatars.dart';
import '../../contribution/presentation/widgets/design_sheet.dart';
import '../../history/domain/contribution_view.dart';
import '../../tour/tour_controller.dart';

enum _Section { none, personal, history, mode }

/// Settings — pixel-perfect to the Figma Settings frames: all collapsed
/// (700:691), Personal info open (707:746), History open (707:805) and Mode
/// open (707:831). One section opens at a time; its chevron flips.
///
///  * Personal info — name and phone; edit (pencil) and "Delete my account".
///  * History — "Since" + the registration date (tap for the list) and "Download
///    receipts" (a receipts file to save or share).
///  * Mode — "Secret mode on/off" and the "Give anonymously" toggle.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _Section _open = _Section.none;

  void _toggle(_Section s) => setState(() => _open = _open == s ? _Section.none : s);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final secret = user?.visibility == 'secret';
    final since = user == null ? '' : 'Since ${DateFormat('MMM d, yyyy').format(user.registeredAt)}';

    // Vertical rhythm measured across the four Settings frames.
    final pOpen = _open == _Section.personal;
    final hOpen = _open == _Section.history;
    final mOpen = _open == _Section.mode;
    final d1 = pOpen ? 553.0 : 492.0; // divider under Personal info
    final hHeader = d1 + (pOpen ? 31 : 21);
    final hDetail = d1 + 86;
    final d2 = hDetail + (hOpen ? 115 : 54); // divider under History
    final mHeader = d2 + 32;
    final mDetail = mHeader + 55;

    return Scaffold(
      backgroundColor: Colors.white,
      body: PixelCanvas(
        background: Colors.white,
        fit: true,
        builder: (context, px) {
          Widget text(double left, double top, String value, {double size = 16, Color color = Colors.black}) =>
              px.text(left, top, value, size: size, weight: BType.light, color: color,
                  fontFamily: BType.family, height: null, width: 260, maxLines: 1, ellipsis: true);

          Widget icon(double left, double top, String name, VoidCallback? onTap, {String? label, double w = 24, double h = 24, bool flip = false}) {
            final glyph = DesignIcon(name, scale: px.scale, width: w, height: h, tint: false);
            return px.at(left - 12, top - 12, width: w + 24, height: h + 24, child: Semantics(
              button: onTap != null,
              label: label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Center(child: AnimatedRotation(turns: flip ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: glyph)),
              ),
            ));
          }

          Widget header(double top, String label, _Section s) => px.at(50, top - 10, width: 320, height: 50, child: Semantics(
                button: true,
                label: label,
                expanded: _open == s,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _toggle(s)),
              ));

          Widget divider(double top) => px.at(62, top - 0.5, width: 332, height: 1,
              child: const ColoredBox(color: AppColors.placeholder));

          return [
            // Gear (62, 85) — back to the menu. Avatar (318, 76, ⌀48).
            icon(62, 85, 'settings', () => Navigator.of(context).maybePop(), label: 'Close settings'),
            px.at(318, 76, width: 48, height: 48, child: const UserAvatar(editable: true)),

            px.text(0, 205, 'Settings', size: 24, weight: BType.light, color: Colors.black,
                width: 420, align: TextAlign.center, fontFamily: BType.family, height: null),
            // "Bahasha" pill: #F5F5F5, radius 29, padding 10, top 252.
            px.at(0, 252, width: 420, child: Center(child: Container(
              padding: EdgeInsets.all(10 * px.scale),
              decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(29 * px.scale)),
              child: Text('Bahasha', style: BType.elms(16 * px.scale)),
            ))),

            // --- Personal info ------------------------------------------------
            px.at(40, 335, width: 340, height: d1 - 335 - 6, child: SizedBox(key: TourKeys.settingsPersonal)),
            text(62, 347, 'Personal info', size: 24),
            header(347, 'Personal info', _Section.personal),
            icon(330, 349, 'chevron_down', () => _toggle(_Section.personal), w: 24, h: 27, flip: pOpen),
            text(pOpen ? 64 : 62, 402, (user?.fullName ?? '').trim()),
            text(pOpen ? 64 : 62, 439, user?.phone ?? ''),
            if (pOpen) ...[
              icon(330, 427, 'edit_2', user == null ? null : () => _editDetails(user), label: 'Edit personal info'),
              px.at(50, 488, width: 320, height: 46, child: Semantics(
                button: true,
                label: 'Delete my account',
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _deleteAccount),
              )),
              text(63, 500, 'Delete my account', color: AppColors.red),
              icon(330, 500, 'x_circle', _deleteAccount, label: 'Delete my account'),
            ],
            divider(d1),

            // --- History ------------------------------------------------------
            text(62, hHeader, 'History', size: 24),
            header(hHeader, 'History', _Section.history),
            icon(330, hHeader + 2, 'chevron_down', () => _toggle(_Section.history), w: 24, h: 27, flip: hOpen),
            px.at(50, hDetail - 10, width: 260, height: 40, child: Semantics(
              button: true,
              label: 'View giving history',
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _openHistory),
            )),
            text(62, hDetail, since),
            if (hOpen) ...[
              px.at(50, hDetail + 51, width: 320, height: 46, child: Semantics(
                button: true,
                label: 'Download receipts',
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _downloadReceipts),
              )),
              text(62, hDetail + 63, 'Download receipts', color: AppColors.blue),
              icon(330, hDetail + 62, 'download_circle', _downloadReceipts, label: 'Download receipts'),
            ],
            divider(d2),

            // --- Mode ---------------------------------------------------------
            text(62, mHeader, 'Mode', size: 24),
            header(mHeader, 'Mode', _Section.mode),
            icon(330, mHeader + 2, 'chevron_down', () => _toggle(_Section.mode), w: 24, h: 27, flip: mOpen),
            text(62, mDetail, secret ? 'Secret mode on' : 'Secret mode off'),
            if (mOpen) ...[
              px.at(50, mDetail + 43, width: 320, height: 46, child: Semantics(
                toggled: secret,
                label: 'Give anonymously',
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _setSecret(!secret)),
              )),
              text(62, mDetail + 55, 'Give anonymously', color: AppColors.blue),
              icon(330, mDetail + 53, secret ? 'toggle_on' : 'toggle', () => _setSecret(!secret), label: 'Give anonymously'),
            ],
          ];
        },
      ),
    );
  }

  Future<void> _setSecret(bool secret) async {
    HapticFeedback.selectionClick();
    await ref.read(registrationRepositoryProvider).setVisibility(secret ? 'secret' : 'open');
    ref.invalidate(currentUserProvider);
  }

  void _openHistory() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _HistoryList()));
  }

  Future<void> _downloadReceipts() async {
    final rows = await ref.read(localDatabaseProvider).history();
    if (!mounted) return;
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(designSnack(context, 'No receipts yet'));
      return;
    }
    final buffer = StringBuffer('Bahasha receipts\n\n');
    for (final r in rows) {
      buffer
        ..writeln(ContributionView(r).shareText)
        ..writeln('—' * 20);
    }
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'bahasha-receipts-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.txt'));
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/plain')], subject: 'Bahasha receipts');
  }

  Future<void> _editDetails(LocalUser user) async {
    final changed = await showDesignSheet<bool>(context, designHeight: 340, builder: (ctx, s) => _EditDetails(user: user, scale: s));
    if (changed == true && mounted) {
      ref.invalidate(currentUserProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(designSnack(context, 'Your details were updated'));
    }
  }

  Future<void> _deleteAccount() async {
    final repo = ref.read(registrationRepositoryProvider);
    final unsettled = await repo.unsettledCount();
    if (!mounted) return;
    final confirmed = await showDesignSheet<bool>(context, designHeight: 300, builder: (ctx, s) {
      return Padding(
        padding: EdgeInsets.fromLTRB(45 * s, 80 * s, 45 * s, 24 * s),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Delete my account?', style: BType.elms(24 * s)),
          SizedBox(height: 14 * s),
          Text(
            'This removes your Bahasha account and giving history from this phone.'
            '${unsettled > 0 ? ' $unsettled offering${unsettled == 1 ? ' has' : 's have'} not reached your church yet and will be lost.' : ''}',
            style: BType.elms(16 * s, height: 1.4),
          ),
          SizedBox(height: 18 * s),
          TextAction(label: 'Delete my account', color: AppColors.red, scale: s, onTap: () => Navigator.of(ctx).pop(true)),
          TextAction(label: 'Keep my account', scale: s, onTap: () => Navigator.of(ctx).pop(false)),
        ]),
      );
    });
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    await repo.deleteLocalAccount();
    await ref.read(prayerOutboxProvider).clear();
    ref.read(basketProvider.notifier).clear();
    ref.invalidate(currentUserProvider);
    navigator.popUntil((r) => r.isFirst);
  }
}

/// Edit name + phone, in the design sheet. Saves through the existing
/// /register reconciliation; shows the backend's reason if it refuses.
class _EditDetails extends ConsumerStatefulWidget {
  const _EditDetails({required this.user, required this.scale});
  final LocalUser user;
  final double scale;

  @override
  ConsumerState<_EditDetails> createState() => _EditDetailsState();
}

class _EditDetailsState extends ConsumerState<_EditDetails> {
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(text: widget.user.phone);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  static bool _validPhone(String v) =>
      RegExp(r'^(0|254|\+254)?[17][0-9]{8}$').hasMatch(v.replaceAll(RegExp(r'[\s-]'), ''));

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Please enter your name');
    if (!_validPhone(phone)) return setState(() => _error = 'Please enter a valid Kenyan phone number');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(registrationRepositoryProvider).updateProfile(fullName: name, phone: phone);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not update your details. Please check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    InputDecoration deco(String hint) => InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: BType.elms(16 * s, color: AppColors.placeholder),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.placeholder)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.blue)),
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(62 * s, 80 * s, 62 * s, 24 * s),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Personal info', style: BType.elms(24 * s)),
        SizedBox(height: 20 * s),
        TextField(controller: _name, textCapitalization: TextCapitalization.words, cursorColor: AppColors.blue,
            style: BType.elms(16 * s), decoration: deco('Your name')),
        SizedBox(height: 16 * s),
        TextField(controller: _phone, keyboardType: TextInputType.phone, cursorColor: AppColors.blue,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
            style: BType.elms(16 * s), decoration: deco('07XX XXX XXX')),
        if (_error != null) ...[
          SizedBox(height: 12 * s),
          Text(_error!, style: BType.elms(14 * s, color: AppColors.red)),
        ],
        SizedBox(height: 12 * s),
        TextAction(label: _saving ? 'Saving…' : 'Save', scale: s, onTap: _saving ? null : _save),
      ]),
    );
  }
}

/// The giving history list (from "Since …"), in the design's type.
class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = MediaQuery.of(context).size.width / 420;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.fromLTRB(50 * s, 20 * s, 24 * s, 12 * s),
            child: Row(children: [
              Semantics(
                button: true,
                label: 'Back',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Padding(
                    padding: EdgeInsets.all(12 * s),
                    child: Transform.rotate(angle: 1.5708, child: DesignIcon('chevron_down', scale: s, width: 24, height: 27, tint: false)),
                  ),
                ),
              ),
              Text('History', style: BType.elms(24 * s)),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<Contribution>>(
              stream: ref.watch(localDatabaseProvider).watchHistory(),
              builder: (context, snap) {
                final rows = snap.data ?? const <Contribution>[];
                if (rows.isEmpty) {
                  return Center(child: Text('No giving yet.', style: BType.elms(16 * s, color: AppColors.wheelGrey)));
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(62 * s, 8 * s, 26 * s, 24 * s),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 16 * s),
                    child: const Divider(height: 1, thickness: 1, color: AppColors.placeholder),
                  ),
                  itemBuilder: (_, i) {
                    final v = ContributionView(rows[i]);
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(v.amountLabel, style: BType.elms(20 * s))),
                        Text(v.statusChip.label, style: BType.elms(14 * s, color: AppColors.wheelGrey)),
                      ]),
                      SizedBox(height: 6 * s),
                      Text(v.dateLabel, style: BType.elms(14 * s, color: AppColors.wheelGrey)),
                      SizedBox(height: 4 * s),
                      Text(v.allocations.map((a) => a.name).join(' · '), style: BType.elms(16 * s)),
                    ]);
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
