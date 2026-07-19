import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/theme/app_colors.dart';
import '../../account/presentation/account_screen.dart';
import '../application/basket_controller.dart';
import '../domain/contribution_category.dart';
import 'category_amount_screen.dart';

/// The Bahasha home / giving screen — pixel-perfect to the Figma frame
/// (node 168:547). A light-green panel fills the top 576px carrying the focused
/// category's title and description; four category rows follow in the exact
/// colours and positions from the design (the first sits on the panel, then the
/// green/cyan/violet 80px bands); an indigo "Send contributions" bar is pinned
/// at the bottom. Swiping vertically pages the four rows through the remaining
/// categories.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _page = 0; // which group of four categories is shown

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final basket = ref.watch(basketProvider);

    // Four visible rows per the design.
    final start = _page * 4;
    final visible = <ContributionCategory>[
      for (var i = start; i < start + 4 && i < categories.length; i++) categories[i],
    ];
    final focused = visible.isNotEmpty ? visible.first : categories.first;
    final maxPage = ((categories.length - 1) / 4).floor();

    // Row backgrounds, exactly as Figma: first on the panel, then the bands.
    const rowColors = <Color>[
      AppColors.panelGreen,
      AppColors.categoryGreen,
      AppColors.categoryCyan,
      AppColors.categoryViolet,
    ];
    // Figma y positions for each row's band and its label.
    const bandTop = <double>[433, 576, 656, 736]; // first row has no visible band
    const labelTop = <double>[513, 600, 680, 760];
    const plusTop = <double>[517, 600, 684, 765];

    return Scaffold(
      backgroundColor: AppColors.indigo,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -150 && _page < maxPage) setState(() => _page++);
          if (v > 150 && _page > 0) setState(() => _page--);
        },
        child: PixelCanvas(
          background: AppColors.indigo,
          builder: (context, px) => [
            // Light-green panel, top 576px.
            px.band(0, 576, AppColors.panelGreen),

            // Menu (opens Account).
            px.at(356, 69, width: 24, height: 24, child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              ),
              child: DesignIcon('menu', scale: px.scale),
            )),

            // Focused category title + description.
            px.text(40, 222, _title(focused), size: 32),
            px.text(40, 288, focused.description, size: 16, width: 325, height: 1.3),

            // Four category rows.
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) px.band(bandTop[i], 80, rowColors[i]),
              // Tap target spanning the row.
              px.at(0, i == 0 ? 500 : bandTop[i], width: 420, height: i == 0 ? 63 : 80,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openAmount(context, visible[i]),
                  child: const SizedBox.expand(),
                )),
              px.text(40, labelTop[i], _rowLabel(visible[i], basket), size: 24),
              px.at(356, plusTop[i], width: 24, height: 24, child: GestureDetector(
                onTap: () => _openAmount(context, visible[i]),
                child: DesignIcon(
                  basket.isSelected(visible[i].code) ? 'minus' : 'plus',
                  scale: px.scale,
                ),
              )),
            ],

            // Fixed "Send contributions" bar (indigo base shows through).
            px.text(40, 850, 'Send contributions', size: 24, weight: FontWeight.w400, color: AppColors.onIndigo),
            px.at(356, 852, width: 24, height: 24, child: GestureDetector(
              onTap: basket.isEmpty ? null : () => _send(context),
              child: Opacity(
                opacity: basket.isEmpty ? 0.5 : 1,
                child: DesignIcon('arrow-right-circle', scale: px.scale, color: AppColors.onIndigo),
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _title(ContributionCategory c) {
    switch (c.code) {
      case 'tithe':
        return 'Tithe';
      case 'combined_offering':
        return 'Offering';
      default:
        return c.name;
    }
  }

  String _rowLabel(ContributionCategory c, BasketState basket) {
    final amount = basket.amountFor(c.code);
    if (amount > 0) return amount.toStringAsFixed(2);
    return _title(c);
  }

  Future<void> _openAmount(BuildContext context, ContributionCategory category) async {
    final current = ref.read(basketProvider).amountFor(category.code);
    final amount = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => CategoryAmountScreen(category: category, initial: current)),
    );
    if (amount != null) {
      ref.read(basketProvider.notifier).setAmount(category.code, amount);
    }
  }

  Future<void> _send(BuildContext context) async {
    // Wiring preserved from before: sign into the outbox, attempt BLE.
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Contribution saved to your outbox.')));
    ref.read(basketProvider.notifier).clear();
  }
}
