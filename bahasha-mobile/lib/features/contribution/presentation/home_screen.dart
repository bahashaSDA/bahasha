import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/icon.dart';
import '../../../core/design/pixel_canvas.dart';
import '../../../core/providers.dart';
import '../../account/presentation/account_screen.dart';
import '../../customize/application/custom_theme.dart';
import '../application/basket_controller.dart';
import '../domain/contribution_category.dart';
import 'category_amount_screen.dart';

/// The Bahasha home / giving screen — pixel-perfect to the Figma frame
/// (node 168:547). A panel fills the top; four category rows follow in their
/// (customisable) band colours at the exact Figma positions; a "Send
/// contributions" bar is pinned at the bottom. Swiping vertically pages the
/// four rows through the remaining categories. Colours come from the giver's
/// CustomTheme so the Customize screen genuinely recolours this screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final basket = ref.watch(basketProvider);
    final theme = ref.watch(customThemeProvider).valueOrNull ?? CustomTheme.fallback;

    final start = _page * 4;
    final visible = <ContributionCategory>[
      for (var i = start; i < start + 4 && i < categories.length; i++) categories[i],
    ];
    final focused = visible.isNotEmpty ? visible.first : categories.first;
    final maxPage = ((categories.length - 1) / 4).floor();

    // Row band tops (row 0 sits on the panel), exactly per Figma.
    const bandTop = <double>[496, 576, 656, 736];
    const labelTop = <double>[513, 600, 680, 760];
    const plusTop = <double>[517, 600, 684, 765];

    return Scaffold(
      backgroundColor: theme.send,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -150 && _page < maxPage) setState(() => _page++);
          if (v > 150 && _page > 0) setState(() => _page--);
        },
        child: PixelCanvas(
          background: theme.send,
          builder: (context, px) => [
            px.band(0, 576, theme.background),

            px.at(356, 69, width: 24, height: 24, child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              ),
              child: DesignIcon('menu', scale: px.scale, color: theme.onBackground),
            )),

            px.text(40, 222, _title(focused), size: 32, color: theme.onBackground),
            px.text(40, 288, focused.description, size: 16, width: 325, height: 1.3, color: theme.onBackground),

            for (var i = 0; i < visible.length; i++) ...[
              px.band(bandTop[i], 80, theme.categoryColor(visible[i].code, start + i)),
              px.at(0, bandTop[i], width: 420, height: 80, child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openAmount(context, visible[i]),
                child: const SizedBox.expand(),
              )),
              px.text(40, labelTop[i], _rowLabel(visible[i], basket), size: 24, width: 290, maxLines: 1, ellipsis: true, color: theme.onBackground),
              px.at(356, plusTop[i], width: 24, height: 24, child: GestureDetector(
                onTap: () => _openAmount(context, visible[i]),
                child: DesignIcon(
                  basket.isSelected(visible[i].code) ? 'minus' : 'plus',
                  scale: px.scale,
                  color: theme.onBackground,
                ),
              )),
            ],

            px.text(40, 850, 'Send contributions', size: 24, weight: FontWeight.w400, color: theme.onSend),
            px.at(356, 852, width: 24, height: 24, child: GestureDetector(
              onTap: basket.isEmpty ? null : () => _send(context),
              child: Opacity(
                opacity: basket.isEmpty ? 0.5 : 1,
                child: DesignIcon('arrow-right-circle', scale: px.scale, color: theme.onSend),
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
    if (amount > 0) return '${_title(c)}  ${amount.toStringAsFixed(2)}';
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

  /// Commit the whole basket (one or many categories) as a single signed
  /// contribution in the local outbox, which History then reflects.
  Future<void> _send(BuildContext context) async {
    final basket = ref.read(basketProvider);
    if (basket.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final user = await ref.read(localDatabaseProvider).currentUser();
    if (user == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please complete registration first')));
      return;
    }
    try {
      await ref.read(contributionRepositoryProvider).createSigned(
            allocations: Map<String, int>.from(basket.amounts),
            user: user,
          );
      final total = basket.total;
      ref.read(basketProvider.notifier).clear();
      messenger.showSnackBar(SnackBar(content: Text('Sent KSh ${total.toStringAsFixed(2)} — saved to your history')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not send: $e')));
    }
  }
}
