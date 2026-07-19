import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../history/presentation/history_screen.dart';
import '../../customize/presentation/customize_screen.dart';

/// Account screen — pixel-perfect to the Figma frame (node 231:1271). Panel-green
/// background; "Account" title; a "Secret giving" / "Give openly" state pill; two
/// full-width cards showing the giver's name and phone; a visibility-toggle row;
/// and the History (green) and Customize (cyan) 80px nav bands at the bottom.
/// Switching visibility affects only future giving (server snapshots the prior
/// state), so past contributions are never retroactively exposed.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final secret = user?.visibility == 'secret';
    final name = (user?.fullName ?? '').toUpperCase();
    final phone = user?.phone ?? '';

    Future<void> toggleVisibility() async {
      await ref.read(registrationRepositoryProvider).setVisibility(secret ? 'open' : 'secret');
      ref.invalidate(currentUserProvider);
    }

    return Scaffold(
      backgroundColor: AppColors.indigo,
      body: PixelCanvas(
        background: AppColors.indigo,
        builder: (context, px) => [
          // Panel green up to the History band.
          px.band(0, 752, AppColors.panelGreen),

          // Close (menu) — dismisses back to Home.
          px.at(356, 69, width: 24, height: 24, child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: DesignIcon('x', scale: px.scale),
          )),

          px.text(40, 222, 'Account', size: 32),

          // Current-visibility pill.
          px.at(40, 280, child: _Pill(
            label: secret ? 'Secret giving' : 'Give openly',
            scale: px.scale,
            filled: secret ? AppColors.panelGreen : Colors.white,
          )),

          // Name + phone cards.
          px.at(0, 411, width: 420, height: 94, child: _card()),
          px.text(40, 445, name, size: 20),
          px.at(0, 505, width: 420, height: 94, child: _card()),
          px.text(40, 539, phone, size: 20),

          // Visibility toggle row.
          px.text(40, 689, secret ? 'Give openly' : 'Give secretly', size: 24),
          px.at(356, 693, width: 24, height: 24, child: GestureDetector(
            onTap: toggleVisibility,
            child: DesignIcon('plus', scale: px.scale),
          )),

          // History band (green).
          px.band(752, 80, AppColors.categoryGreen),
          px.at(0, 752, width: 420, height: 80, child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
            child: const SizedBox.expand(),
          )),
          px.text(40, 776, 'History', size: 24),
          px.at(356, 776, width: 24, height: 24, child: DesignIcon('plus', scale: px.scale)),

          // Customize band (cyan).
          px.band(832, 80, AppColors.categoryCyan),
          px.at(0, 832, width: 420, height: 80, child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomizeScreen())),
            child: const SizedBox.expand(),
          )),
          px.text(40, 856, 'Customize', size: 24),
          px.at(356, 860, width: 24, height: 24, child: DesignIcon('plus', scale: px.scale)),
        ],
      ),
    );
  }

  Widget _card() => const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.panelGreen,
          borderRadius: BorderRadius.all(Radius.circular(1)),
          boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
        ),
      );
}

/// The rounded state pill (radius 34, padding 10, soft shadow) from the design.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.scale, required this.filled});
  final String label;
  final double scale;
  final Color filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10 * scale),
      decoration: BoxDecoration(
        color: filled,
        borderRadius: BorderRadius.circular(34 * scale),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 1.5)],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'BahashaSans',
          fontWeight: FontWeight.w300,
          fontSize: 16 * scale,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
