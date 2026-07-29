import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bahasha/features/contribution/application/basket_controller.dart';
import 'package:bahasha/features/contribution/domain/contribution_category.dart';

// The offertory redesign is driven by the fruit categories and the basket. The
// screens themselves pull in image + SVG asset loading and the SQLite-backed
// user provider, which the flutter_test bundle can't satisfy cleanly (see the
// note in history_test.dart), so — as elsewhere in this suite — we assert the
// pure logic those screens render, which is what can actually break.
void main() {
  test('the ten Figma giving types are present, with a fruit and a give-label', () {
    const expected = <String>[
      'tithe', 'offering', 'church_budget', 'camp_offering', 'camp_budget',
      'mission', 'development', 'children_ministry', 'women_ministry', 'adventist_men',
    ];
    expect(ContributionCategory.seed.map((c) => c.code), expected);
    for (final c in ContributionCategory.seed) {
      expect(c.asset, startsWith('assets/fruits/'));
      expect(c.giveLabel, isNotEmpty);
      expect(c.name, isNotEmpty);
    }
  });

  test('a single giving is added to the basket', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final basket = container.read(basketProvider.notifier);

    basket.setAmount('tithe', 1000);
    expect(container.read(basketProvider).isSelected('tithe'), isTrue);
    expect(container.read(basketProvider).amountFor('tithe'), 1000);
    expect(container.read(basketProvider).total, 1000);
  });

  test('multiple fruits accumulate in the basket (1000 + 500 + 200 = 1700)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final basket = container.read(basketProvider.notifier);

    basket.setAmount('tithe', 1000);
    basket.setAmount('mission', 500);
    basket.setAmount('development', 200);

    expect(container.read(basketProvider).amounts.length, 3);
    expect(container.read(basketProvider).total, 1700);
  });

  test('setting an amount to zero removes the fruit from the basket', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final basket = container.read(basketProvider.notifier);

    basket.setAmount('offering', 300);
    expect(container.read(basketProvider).isSelected('offering'), isTrue);
    basket.setAmount('offering', 0);
    expect(container.read(basketProvider).isSelected('offering'), isFalse);
    expect(container.read(basketProvider).isEmpty, isTrue);
  });
}
