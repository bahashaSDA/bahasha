import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/contribution_category.dart';

/// The giving basket: how much the member has allocated to each category in the
/// current session. This is the mechanism behind multi-category giving
/// (e.g. Tithe 1000 + Mission 500 + Building 200 = 1700) — one basket becomes
/// one signed payload becomes one STK Push.
///
/// Amounts are whole shillings (MPESA settles integers only). A category with a
/// zero/absent entry is simply not selected.
class BasketState {
  const BasketState({this.amounts = const <String, int>{}});

  /// categoryCode -> whole shillings.
  final Map<String, int> amounts;

  int get total => amounts.values.fold(0, (sum, a) => sum + a);

  bool get isEmpty => amounts.values.every((a) => a <= 0);

  int amountFor(String code) => amounts[code] ?? 0;

  bool isSelected(String code) => (amounts[code] ?? 0) > 0;

  BasketState copyWith(Map<String, int> next) => BasketState(amounts: next);
}

class BasketController extends Notifier<BasketState> {
  @override
  BasketState build() => const BasketState();

  /// Set an exact amount for a category. Zero or negative removes it.
  void setAmount(String code, int amount) {
    final next = Map<String, int>.from(state.amounts);
    if (amount <= 0) {
      next.remove(code);
    } else {
      next[code] = amount;
    }
    state = state.copyWith(next);
  }

  /// Remove a category from the basket entirely.
  void remove(String code) {
    if (!state.amounts.containsKey(code)) return;
    final next = Map<String, int>.from(state.amounts)..remove(code);
    state = state.copyWith(next);
  }

  void clear() => state = const BasketState();
}

final basketProvider =
    NotifierProvider<BasketController, BasketState>(BasketController.new);

/// The categories to display. Backed by the seed today; a later provider swaps
/// in the church-specific list fetched from the backend and cached offline.
final categoriesProvider = Provider<List<ContributionCategory>>(
  (ref) => ContributionCategory.seed,
);
