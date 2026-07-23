import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/data/local_database.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../customize/application/custom_theme.dart';
import '../domain/contribution_view.dart';

/// Live stream of local contribution history, newest first.
final historyProvider = StreamProvider<List<Contribution>>((ref) {
  return ref.watch(localDatabaseProvider).watchHistory();
});

/// History screen — pixel-perfect to the Figma frame (node 239:1379). Green
/// screen; "History" title; a stack of date/amount cards; each with a trash icon
/// (tap → confirm → delete) and share (tap the card → share that transaction to
/// anywhere). A fixed "Share history" action shares the whole list.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static final _dateFmt = DateFormat('dd MMMM');
  static final _amountFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(historyProvider).valueOrNull ?? const <Contribution>[];
    final theme = ref.watch(customThemeProvider).valueOrNull ?? CustomTheme.fallback;
    final bg = theme.isAllWhite ? Colors.white : AppColors.categoryGreen;

    return Scaffold(
      backgroundColor: bg,
      body: PixelCanvas(
        background: bg,
        scrollable: true,
        builder: (context, px) => [
          px.at(356, 69, width: 24, height: 24, child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: DesignIcon('menu', scale: px.scale),
          )),

          px.text(40, 222, 'History', size: 32),

          if (rows.isEmpty)
            px.text(40, 360, 'No contributions yet.', size: 20, color: AppColors.ink)
          else
            for (var i = 0; i < rows.length; i++) ...[
              px.at(0, 328 + i * 94.0, width: 420, height: 94, child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3)],
                ),
              )),
              // Tap the card to share this single transaction.
              px.at(0, 328 + i * 94.0, width: 420, height: 94, child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _shareOne(ref, rows[i]),
                child: const SizedBox.expand(),
              )),
              px.text(40, 360 + i * 94.0, _dateFmt.format(rows[i].createdAt), size: 24),
              px.text(210, 360 + i * 94.0, _amountFmt.format(rows[i].totalAmount), size: 24),
              // Trash icon → confirm → delete.
              px.at(356, 360 + i * 94.0, width: 24, height: 24, child: GestureDetector(
                onTap: () => _confirmDelete(context, ref, rows[i]),
                child: DesignIcon('trash', scale: px.scale, color: AppColors.ink),
              )),
            ],

          // Fixed "Share history" (all transactions).
          px.at(0, rows.length <= 4 ? 835 : (328 + rows.length * 94.0 + 20), width: 420, height: 40,
            child: const SizedBox.shrink()),
          px.text(40, rows.length <= 4 ? 835 : (328 + rows.length * 94.0 + 20), 'Share history', size: 24),
          px.at(356, (rows.length <= 4 ? 835 : (328 + rows.length * 94.0 + 20)) + 7, width: 24, height: 24,
            child: GestureDetector(
              onTap: () => _shareAll(rows),
              child: DesignIcon('plus', scale: px.scale),
            )),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Contribution row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this record?'),
        content: Text('${_dateFmt.format(row.createdAt)} — KSh ${_amountFmt.format(row.totalAmount)}\n\n'
            'This removes it from your history on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE03131))),
          ),
        ],
      ),
    );
    if (ok == true) {
      final db = ref.read(localDatabaseProvider);
      await (db.delete(db.contributions)..where((t) => t.id.equals(row.id))).go();
    }
  }

  Future<void> _shareOne(WidgetRef ref, Contribution row) async {
    await Share.share(ContributionView(row).shareText, subject: 'Bahasha contribution');
  }

  Future<void> _shareAll(List<Contribution> rows) async {
    if (rows.isEmpty) return;
    final buffer = StringBuffer('Bahasha giving history\n\n');
    for (final r in rows) {
      buffer.writeln('${_dateFmt.format(r.createdAt)} — KSh ${_amountFmt.format(r.totalAmount)}');
    }
    await Share.share(buffer.toString(), subject: 'Bahasha history');
  }
}
