import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../application/basket_controller.dart';
import '../domain/contribution_category.dart';
import 'widgets/amount_sheet.dart';
import 'widgets/category_bar.dart';

/// The Bahasha home / giving screen.
///
/// Layout follows the Figma frame (420×912): a light-green information panel at
/// the top describing the focused category, a scrolling list of flat category
/// bars (only ~four visible at once, swipe to reveal the rest), and a fixed
/// indigo "Send contributions" bar pinned to the bottom regardless of scroll.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final basket = ref.watch(basketProvider);

    // The panel describes the "focused" category. It defaults to the first
    // (Tithe, matching the Figma) and follows the most recently selected one.
    final focused = categories.first;

    return Scaffold(
      backgroundColor: AppColors.indigo,
      body: Column(
        children: <Widget>[
          _Panel(category: focused),
          // The category list. Its background is panel-green so the first row
          // (index 0 in the colour cycle) flows out of the panel seamlessly,
          // exactly as in the design.
          Expanded(
            child: Container(
              color: AppColors.panelGreen,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryBar(
                    category: category,
                    color: ContributionCategory.colorForIndex(index),
                    amount: basket.amountFor(category.code),
                    onAdd: () => _edit(context, ref, category),
                    onRemove: () => ref.read(basketProvider.notifier).remove(category.code),
                  );
                },
              ),
            ),
          ),
          _SendBar(total: basket.total, enabled: !basket.isEmpty),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, ContributionCategory category) async {
    final current = ref.read(basketProvider).amountFor(category.code);
    final amount = await AmountSheet.show(context, category: category, initial: current);
    if (amount != null) {
      ref.read(basketProvider.notifier).setAmount(category.code, amount);
    }
  }
}

/// The top information panel: menu affordance, focused category title, and its
/// description. Heights are anchored to the Figma (menu at y≈69, title at y≈222,
/// description at y≈288) via padding, so it reads identically on a phone.
class _Panel extends StatelessWidget {
  const _Panel({required this.category});

  final ContributionCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.panelGreen, AppColors.panelGreen],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 24, 40, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header: menu icon, right-aligned (Figma x≈356 in a 420 frame).
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {},
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                  icon: SvgPicture.asset(
                    'assets/icons/menu.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(AppColors.ink, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(height: 96),
              // The focused category's short display title (Figma shows "Tithe").
              Text(_shortTitle(category), style: AppTypography.title),
              const SizedBox(height: 20),
              Text(category.description, style: AppTypography.description),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// The panel headline uses the short, familiar name ("Tithe"), while the row
  /// list uses the full formal name ("God's Tithe").
  static String _shortTitle(ContributionCategory c) {
    switch (c.code) {
      case 'tithe':
        return 'Tithe';
      case 'combined_offering':
        return 'Offering';
      default:
        return c.name;
    }
  }
}

/// The fixed bottom action bar. Always visible, never scrolls. Shows the running
/// total once anything is selected and reads "Send contributions" with the
/// circled-arrow affordance from the design.
class _SendBar extends StatelessWidget {
  const _SendBar({required this.total, required this.enabled});

  final int total;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.indigo,
      child: InkWell(
        onTap: enabled ? () {} : null,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 22, 40, 22),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Send contributions', style: AppTypography.action),
                      // Running total appears only when there is something to send,
                      // so the resting state matches the Figma exactly.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.topLeft,
                        child: total > 0
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'KSh ${total.toStringAsFixed(2)}',
                                  style: AppTypography.description.copyWith(
                                    color: AppColors.onIndigo,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Opacity(
                  opacity: enabled ? 1 : 0.5,
                  child: SvgPicture.asset(
                    'assets/icons/arrow-right-circle.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(AppColors.onIndigo, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
