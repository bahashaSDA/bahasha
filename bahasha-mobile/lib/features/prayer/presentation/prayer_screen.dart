import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/type.dart';
import '../../../core/theme/app_colors.dart';
import '../../contribution/presentation/widgets/design_sheet.dart';
import '../data/prayer_outbox.dart';

/// The silent-prayer screen — pixel-perfect to the Figma Prayer screen
/// (700:555): a white page, the blue send icon at (335, 82), and "Add a silent
/// prayer" (Elms Sans Light 24, #C8C8C8 placeholder) with the grey info icon,
/// sitting just above the keyboard (the Figma's grey block from y 628).
///
/// Optional by design. Tapping send returns the text (an empty/whitespace
/// text means "no prayer"); going back returns null and discards anything
/// typed, so nothing is saved unless the giver confirms.
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key, this.initial});

  /// A prayer already attached to this offering, to edit.
  final String? initial;

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  late final TextEditingController _text = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_text.text);

  void _info() {
    showDesignSheet<void>(context, designHeight: 240, builder: (ctx, s) {
      return Padding(
        padding: EdgeInsets.fromLTRB(45 * s, 80 * s, 45 * s, 48 * s),
        child: Text(
          'Your silent prayer is anonymous: no name or number goes with it. '
          'Your church’s prayer team prays over it this Sabbath, and it is cleared on Sunday. '
          'Adding a prayer is optional.',
          textAlign: TextAlign.center,
          style: BType.elms(18 * s, height: 1.35),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final s = mq.size.width / 420;
    final keyboard = mq.viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        // Send (335, 82, 36) — confirm and return to Send.
        Positioned(
          left: (335 - 6) * s, top: (82 - 6) * s, width: 48 * s, height: 48 * s,
          child: Semantics(
            button: true,
            label: 'Add prayer and continue',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _confirm,
              child: Center(child: DesignIcon('send', scale: s, size: 36, tint: false)),
            ),
          ),
        ),
        // The prayer line, ~35px above the keyboard (Figma: text 559–590,
        // keyboard from 628). Grows upward as the prayer gets longer.
        Positioned(
          left: 45 * s, right: 0, bottom: keyboard + 35 * s,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: _text,
                autofocus: true,
                minLines: 1,
                maxLines: 6,
                maxLength: PrayerRequest.maxLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: AppColors.blue,
                style: BType.elms(24 * s),
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Add a silent prayer',
                  hintStyle: BType.elms(24 * s, color: AppColors.placeholder),
                ),
              ),
            ),
            // Info (342, 563, 24): what happens to a prayer.
            Semantics(
              button: true,
              label: 'About prayer requests',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _info,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12 * s, 4 * s, (420 - 342 - 24) * s, 3 * s),
                  child: DesignIcon('info', scale: s, tint: false),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
