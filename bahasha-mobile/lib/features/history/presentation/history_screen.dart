import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/data/local_database.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/contribution_view.dart';

/// Live stream of local contribution history, newest first.
final historyProvider = StreamProvider<List<Contribution>>((ref) {
  return ref.watch(localDatabaseProvider).watchHistory();
});

/// History screen — pixel-perfect to the Figma frame (node 239:1379). Solid
/// green background; "History" title; a stack of date/amount cards (first at
/// y=328, each 94px tall, with the subtle shadow separator from the design);
/// and a fixed "Share history" action at the bottom that opens the Android
/// share sheet.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static final _dateFmt = DateFormat('dd MMMM');
  static final _amountFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(historyProvider).valueOrNull ?? const <Contribution>[];

    return Scaffold(
      backgroundColor: AppColors.categoryGreen,
      body: PixelCanvas(
        background: AppColors.categoryGreen,
        scrollable: false,
        builder: (context, px) => [
          px.at(356, 69, width: 24, height: 24, child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: DesignIcon('menu', scale: px.scale),
          )),

          px.text(40, 222, 'History', size: 32),

          // Entry cards from y=328, each 94px tall.
          for (var i = 0; i < rows.length && i < 5; i++) ...[
            px.at(0, 328 + i * 94.0, width: 420, height: 94, child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.categoryGreen,
                boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
              ),
            )),
            px.text(40, 360 + i * 94.0, _dateFmt.format(rows[i].createdAt), size: 24),
            px.text(300, 360 + i * 94.0, _amountFmt.format(rows[i].totalAmount), size: 24),
          ],

          // Fixed "Share history".
          px.text(40, 835, 'Share history', size: 24),
          px.at(356, 842, width: 24, height: 24, child: GestureDetector(
            onTap: () => _share(rows),
            child: DesignIcon('plus', scale: px.scale),
          )),
        ],
      ),
    );
  }

  Future<void> _share(List<Contribution> rows) async {
    if (rows.isEmpty) return;
    final buffer = StringBuffer('Bahasha giving history\n\n');
    for (final r in rows) {
      buffer.writeln('${_dateFmt.format(r.createdAt)} — KSh ${_amountFmt.format(r.totalAmount)}');
    }
    final view = rows.isNotEmpty ? ContributionView(rows.first) : null;
    if (view != null) buffer.writeln('\nRef: ${rows.first.id.substring(0, 8).toUpperCase()}');
    await Share.share(buffer.toString(), subject: 'Bahasha history');
  }
}
