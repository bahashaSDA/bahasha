import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ble/vendor_presence.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/design/type.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../prayer/data/prayer_outbox.dart';
import '../../prayer/presentation/prayer_screen.dart';
import '../../tour/tour_controller.dart';
import '../application/basket_controller.dart';
import '../application/giving_relay.dart';
import '../domain/contribution_category.dart';
import 'home_screen.dart' show designSnack;
import 'thank_you_screen.dart';
import 'widgets/amount_text.dart';
import 'widgets/avatars.dart';
import 'widgets/design_sheet.dart';
import 'widgets/design_wheel.dart';

/// Send — pixel-perfect to the Figma Send frame (621:76), with the Vendor
/// Card (692:440) and Missing Vendor (700:504) states.
///
/// Top: the giver → the church's collector, joined by a dashed arrow (blue
/// when a CVendor hub is in Bluetooth range, red with an empty avatar when
/// none is). The wheel reviews the offering: "Total" plus each category given
/// to; the bubble on Total adds an optional silent prayer.
///
/// Flow: tap Send → the Prayer screen opens (optional — type a prayer and tap
/// its send icon, or just go back to skip) → back here → tap Send again to
/// give. The offering is saved on the phone first; only once that has
/// succeeded is the prayer (if any) queued, so a failed offering never leaves
/// an orphan prayer. Then, if a collector is in range, both are handed over
/// Bluetooth (GivingRelay) — Bahasha itself never uses the internet. Prayers
/// are anonymous: nothing links them to the giver or to the offering.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key, this.preview = false});

  /// Tour preview: shows the real screen without scanning or sending.
  final bool preview;

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

enum _Phase { idle, sending, failed }

class _SendScreenState extends ConsumerState<SendScreen> with SingleTickerProviderStateMixin {
  /// Figma Send frame geometry (621:76).
  static const _wheel = WheelGeometry(
    prevTop: 485, cardTop: 543, nextTop: 679,
    cardLeft: 63, textLeft: 89, trailingLeft: 302,
  );

  late final AnimationController _pulse;

  int _focus = 0;
  String? _prayer; // confirmed prayer text, attached to this offering
  bool _prayerStepDone = false;
  _Phase _phase = _Phase.idle;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    if (!widget.preview) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(vendorPresenceProvider.notifier).scan());
      // Once a collector is found, hand over anything already waiting on the
      // phone (earlier offerings, prayers, a registration).
      ref.listenManual<VendorPresence>(vendorPresenceProvider, (was, now) async {
        if (now.status == VendorStatus.found && was?.status != VendorStatus.found) {
          final relay = ref.read(givingRelayProvider);
          if (await relay.hasWork()) unawaited(relay.drain());
        }
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Wheel items: Total first, then the categories given to. Reversed so the
  /// first category sits above Total and the next below, as in the Figma.
  List<ContributionCategory?> _items(BasketState basket) {
    final chosen = [for (final c in ref.read(categoriesProvider)) if (basket.isSelected(c.code)) c];
    return [null, ...chosen.reversed];
  }

  Future<void> _openPrayer() async {
    if (widget.preview || _phase == _Phase.sending) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => PrayerScreen(initial: _prayer)),
    );
    if (!mounted) return;
    setState(() {
      _prayerStepDone = true;
      // null = backed out: keep whatever was attached before (nothing new is
      // saved). A confirmed empty prayer detaches it.
      if (result != null) _prayer = PrayerRequest.clean(result);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(designSnack(context, _prayer != null ? 'Prayer added. Tap Send to give.' : 'Tap Send to give.'));
  }

  Future<void> _onSend() async {
    if (widget.preview || _phase == _Phase.sending) return;
    if (!_prayerStepDone) return _openPrayer();

    final basket = ref.read(basketProvider);
    if (basket.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _phase = _Phase.sending);
    try {
      final user = await ref.read(localDatabaseProvider).currentUser();
      if (user == null) throw StateError('Please complete registration first');
      final total = basket.total;
      // 1. Saved on the phone first — nothing is lost from here on.
      await ref.read(contributionRepositoryProvider).createQueued(
            allocations: Map<String, int>.from(basket.amounts),
            user: user,
          );
      // 2. Only now attach the (anonymous) prayer.
      var prayerQueued = false;
      if (_prayer != null) {
        try {
          prayerQueued = await ref.read(prayerOutboxProvider).enqueue(text: _prayer) != null;
        } catch (_) {
          prayerQueued = false;
        }
      }
      ref.read(basketProvider.notifier).clear();
      ref.read(currentCategoryProvider.notifier).state = 'tithe';

      // 3. Hand it to the church's collector over Bluetooth, if one is near.
      var report = RelayReport.nothingToDo;
      if (ref.read(vendorPresenceProvider).status == VendorStatus.found) {
        report = await ref
            .read(givingRelayProvider)
            .drain()
            .timeout(const Duration(seconds: 45), onTimeout: () => RelayReport.nothingToDo);
      }
      navigator.pushReplacement(MaterialPageRoute(
        builder: (_) => ThankYouScreen(
          total: total,
          report: report,
          prayerQueued: prayerQueued,
          prayerFailed: _prayer != null && !prayerQueued,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.failed);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(designSnack(context, 'Your offering was not saved. Please tap Send to try again.', color: AppColors.red));
    }
  }

  void _editCategory(ContributionCategory c) {
    if (widget.preview) return;
    ref.read(currentCategoryProvider.notifier).state = c.code;
    ref.read(homePickingProvider.notifier).state = false;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final basket = ref.watch(basketProvider);
    final vendor = widget.preview ? const VendorPresence(VendorStatus.searching) : ref.watch(vendorPresenceProvider);
    final items = _items(basket);
    final focus = _focus.clamp(0, items.length - 1);
    final focused = items[focus];
    final sending = _phase == _Phase.sending;

    // If a category is removed while focused, fall back to Total.
    if (_focus >= items.length) _focus = 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: PixelCanvas(
        background: Colors.white,
        fit: true,
        builder: (context, px) => [
          // Giver (63, 79, ⌀37).
          px.at(63, 79, width: 37, height: 37, child: const UserAvatar()),
          // Dashed arrow (111, 100 − 7.36; 202 × 14.73).
          px.at(111, 100 - 7.364, width: 202, height: 14.728, child: _arrow(vendor.status)),
          // Collector (321, 79, ⌀37) — tap for the Vendor Card.
          px.at(321 - 6, 79 - 6, width: 49, height: 49, child: GestureDetector(
            key: TourKeys.sendVendor,
            behavior: HitTestBehavior.opaque,
            onTap: () => _showVendor(vendor),
            child: Center(child: SizedBox(width: 37 * px.scale, height: 37 * px.scale, child: _vendorAvatar(vendor.status))),
          )),

          px.text(0, 189, focused?.name ?? 'Total', size: 24, weight: BType.light, color: Colors.black,
              width: 420, align: TextAlign.center, fontFamily: BType.family, height: null),
          px.at(0, 315, width: 420, child: AmountText(
            amount: focused == null ? basket.total : basket.amountFor(focused.code), scale: px.scale)),

          px.at(0, DesignWheel.top(_wheel), width: 420, height: DesignWheel.bottom(_wheel) - DesignWheel.top(_wheel),
              child: DesignWheel(
            scale: px.scale,
            geometry: _wheel,
            items: [for (final c in items) c?.name ?? 'Total'],
            index: focus,
            onChanged: (i) => setState(() => _focus = i),
            onCardTap: (i) {
              final c = items[i];
              if (c == null) {
                _openPrayer();
              } else {
                _editCategory(c);
              }
            },
            cardKey: TourKeys.sendTotal,
            trailingKey: TourKeys.sendPrayer,
            onTrailingTap: (_) => _openPrayer(),
            trailing: (i) => items[i] == null
                ? DesignIcon(_prayer != null ? 'message_circle_filled' : 'message_circle', scale: px.scale, tint: false)
                : null,
          )),

          // "Send" (89, 836 — Light 24, blue) + plane (304, 834, 36).
          px.at(70, 818, width: 300, height: 70, child: Semantics(
            button: true,
            label: 'Send offering',
            child: GestureDetector(
              key: TourKeys.sendButton,
              behavior: HitTestBehavior.opaque,
              onTap: sending ? null : _onSend,
              child: const SizedBox.expand(),
            ),
          )),
          px.text(89, 836, switch (_phase) {
            _Phase.sending => 'Sending…',
            _Phase.failed => 'Try again',
            _Phase.idle => 'Send',
          }, size: 24, weight: BType.light, color: AppColors.blue, fontFamily: BType.family, height: null),
          px.at(304, 834, width: 36, height: 36, child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: sending ? 0.35 : 1,
              child: DesignIcon('send', scale: px.scale, size: 36, tint: false),
            ),
          )),
        ],
      ),
    );
  }

  Widget _arrow(VendorStatus status) {
    final asset = status == VendorStatus.missing ? 'assets/icons/vendor_arrow_red.png' : 'assets/icons/vendor_arrow.png';
    final img = Image.asset(asset, fit: BoxFit.fill);
    if (status != VendorStatus.searching) return img;
    // Still looking: the blue line breathes until a collector is found.
    return FadeTransition(opacity: Tween<double>(begin: 0.25, end: 0.8).animate(_pulse), child: img);
  }

  Widget _vendorAvatar(VendorStatus status) {
    if (status == VendorStatus.found) {
      return ClipOval(child: Image.asset('assets/icons/vendor_logo.png', fit: BoxFit.cover));
    }
    return const DecoratedBox(decoration: BoxDecoration(color: AppColors.vendorMissing, shape: BoxShape.circle));
  }

  void _showVendor(VendorPresence vendor) {
    if (widget.preview) return;
    showDesignSheet<void>(context, builder: (ctx, s) {
      return Consumer(builder: (ctx, ref, _) {
        final v = ref.watch(vendorPresenceProvider);
        final found = v.status == VendorStatus.found;
        final message = switch (v.status) {
          VendorStatus.found => 'Hi, I’m ${v.name ?? 'your church’s collector'}, receiving offerings here',
          VendorStatus.searching => 'Looking for your church’s collector nearby…',
          VendorStatus.missing => 'No collector nearby yet. Your offering is kept safely on your phone.',
        };
        return Column(mainAxisSize: MainAxisSize.min, children: [
          PortraitMessage(
            scale: s,
            portrait: found
                ? Image.asset('assets/icons/vendor_logo.png', fit: BoxFit.cover)
                : const ColoredBox(color: AppColors.vendorMissing),
            message: message,
          ),
          if (v.status == VendorStatus.missing)
            Padding(
              padding: EdgeInsets.only(bottom: 16 * s),
              child: TextAction(
                label: 'Search again',
                scale: s,
                onTap: () => ref.read(vendorPresenceProvider.notifier).scan(),
              ),
            ),
        ]);
      });
    });
  }
}
