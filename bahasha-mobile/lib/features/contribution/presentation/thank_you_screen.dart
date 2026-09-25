import 'package:flutter/material.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/design/type.dart';
import '../../../core/theme/app_colors.dart';
import '../application/giving_relay.dart';
import 'widgets/amount_text.dart';

/// Shown once an offering has been signed into the outbox. The Figma has no
/// frame for this state, so it reuses the Send frame's exact structure: the
/// centred title (top 189), the ExtraLight figure (top 315), and the blue
/// text action with its plane at the bottom (89/304, 836) — here "Give
/// again", which returns to a fresh keypad.
class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({
    super.key,
    required this.total,
    this.report = RelayReport.nothingToDo,
    this.prayerQueued = false,
    this.prayerFailed = false,
  });

  final int total;

  /// What the Bluetooth hand-over to the church's collector achieved.
  final RelayReport report;
  final bool prayerQueued;
  final bool prayerFailed;

  /// One honest line about where the offering is now.
  static String handoverLine(RelayReport r) {
    if (r.registrationRefused) {
      return 'Saved on your phone. The collector could not confirm your details. Please check your phone number in Settings.';
    }
    if (r.offeringsHanded > 0 && r.offeringsWaiting == 0) {
      final to = r.church == null ? 'your church’s collector' : r.church!;
      return 'Handed to $to.';
    }
    if (r.registrationPending) {
      return 'Saved on your phone. The collector is offline right now, so it will be handed over when you are next near it.';
    }
    return 'Saved on your phone. It will be handed to your church’s collector when you are near one.';
  }

  @override
  Widget build(BuildContext context) {
    final prayerNote = prayerFailed
        ? ' Your prayer could not be kept. Please add it again next time.'
        : !prayerQueued
            ? ''
            : report.prayersHanded > 0
                ? ' Your prayer is with the prayer team for this Sabbath.'
                : ' Your prayer will go with it.';
    final note = handoverLine(report) + prayerNote;

    void home() => Navigator.of(context).popUntil((r) => r.isFirst);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: PixelCanvas(
          background: Colors.white,
          fit: true,
          builder: (context, px) => [
            px.text(0, 189, 'Thank you', size: 24, weight: BType.light, color: Colors.black,
                width: 420, align: TextAlign.center, fontFamily: BType.family, height: null),
            px.at(0, 315, width: 420, child: AmountText(amount: total, scale: px.scale)),
            px.text(60, 485, 'Dearly beloved of the Lord, be blessed.', size: 20, weight: BType.light,
                color: Colors.black, width: 300, align: TextAlign.center, fontFamily: BType.family, height: 1.35),
            px.text(60, 590, note, size: 16, weight: BType.light,
                color: prayerFailed || report.registrationRefused ? AppColors.red : AppColors.wheelGrey,
                width: 300, align: TextAlign.center, fontFamily: BType.family, height: 1.35),
            px.at(70, 818, width: 300, height: 70, child: Semantics(
              button: true,
              label: 'Give again',
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: home, child: const SizedBox.expand()),
            )),
            px.text(89, 836, 'Give again', size: 24, weight: BType.light, color: AppColors.blue,
                fontFamily: BType.family, height: null),
            px.at(304, 834, width: 36, height: 36,
                child: IgnorePointer(child: DesignIcon('send', scale: px.scale, size: 36, tint: false))),
          ],
        ),
      ),
    );
  }
}
