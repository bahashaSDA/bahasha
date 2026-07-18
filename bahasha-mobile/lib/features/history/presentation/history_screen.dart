import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/data/local_database.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/contribution_view.dart';

/// Live stream of the local contribution history, newest first.
final historyProvider = StreamProvider<List<Contribution>>((ref) {
  return ref.watch(localDatabaseProvider).watchHistory();
});

/// Contribution history. Each card can be swiped horizontally: swipe right to
/// share (to WhatsApp, Email, Drive, Telegram, Bluetooth, Nearby Share — the
/// Android share sheet), swipe left to delete. Empty and populated states are
/// both handled; nothing scrolls awkwardly.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.panelGreen,
      appBar: AppBar(
        backgroundColor: AppColors.panelGreen,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Your giving', style: AppTypography.title.copyWith(fontSize: 24)),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.indigo)),
        error: (e, _) => Center(child: Text('Could not load history: $e', style: AppTypography.description)),
        data: (rows) {
          if (rows.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _HistoryCard(view: ContributionView(rows[i])),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.view});

  final ContributionView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chip = view.statusChip;
    return Dismissible(
      key: ValueKey(view.row.id),
      // Swipe right → share. We confirm=false so the card springs back after.
      background: _swipeBg(Alignment.centerLeft, Icons.share, 'Share', AppColors.categoryCyan),
      secondaryBackground:
          _swipeBg(Alignment.centerRight, Icons.delete_outline, 'Delete', const Color(0xFFE03131)),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _share();
          return false; // sharing doesn't remove the card
        }
        return _confirmDelete(context);
      },
      onDismissed: (_) => _delete(ref),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(view.amountLabel, style: AppTypography.title.copyWith(fontSize: 26)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: chip.bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    chip.label,
                    style: AppTypography.description.copyWith(color: chip.color, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(view.dateLabel, style: AppTypography.description.copyWith(fontSize: 13, color: AppColors.inkMuted)),
            const SizedBox(height: 12),
            ...view.allocations.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(a.name, style: AppTypography.description.copyWith(fontSize: 14))),
                    Text(
                      NumberFormatShim.money(a.amount),
                      style: AppTypography.rowLabel.copyWith(fontSize: 15, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share, size: 18, color: AppColors.indigo),
                  label: Text('Share', style: AppTypography.description.copyWith(color: AppColors.indigo)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share() => Share.share(view.shareText, subject: 'Bahasha contribution');

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text('This removes it from your history on this device only.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _delete(WidgetRef ref) async {
    final db = ref.read(localDatabaseProvider);
    await (db.delete(db.contributions)..where((t) => t.id.equals(view.row.id))).go();
  }

  Widget _swipeBg(Alignment align, IconData icon, String label, Color color) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.description.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

/// Tiny formatting helper so allocation rows share the currency style without
/// importing intl at each call site.
class NumberFormatShim {
  static String money(int v) => 'KSh ${v.toStringAsFixed(0)}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.volunteer_activism_outlined, size: 64, color: AppColors.indigo),
            const SizedBox(height: 16),
            Text('No contributions yet', style: AppTypography.title.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              'When you give, your contributions appear here. '
              'Swipe a card to share or delete it.',
              textAlign: TextAlign.center,
              style: AppTypography.description,
            ),
          ],
        ),
      ),
    );
  }
}
