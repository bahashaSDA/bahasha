import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bahasha/features/contribution/presentation/home_screen.dart';
import 'package:bahasha/features/contribution/application/basket_controller.dart';
import 'package:bahasha/core/theme/app_theme.dart';

Widget _wrap() => ProviderScope(
      child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
    );

void main() {
  testWidgets('Home renders the panel headline and the category list', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // Panel headline (short title) and the fixed action bar.
    expect(find.text('Tithe'), findsOneWidget);
    expect(find.text('Send contributions'), findsOneWidget);

    // Category rows render their full names.
    expect(find.text("God's Tithe"), findsOneWidget);
    expect(find.text('Combined Offering'), findsOneWidget);
  });

  testWidgets('Selecting a category shows its amount and the running total', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // Drive the basket directly (the amount sheet is covered separately),
    // proving the Home reflects basket state: label flips to the amount and the
    // Send bar shows the total.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    container.read(basketProvider.notifier).setAmount('tithe', 1000);
    await tester.pumpAndSettle();

    expect(find.text('1000.00'), findsOneWidget); // row shows the amount
    expect(find.text('KSh 1000.00'), findsOneWidget); // send bar shows the total
    expect(find.text("God's Tithe"), findsNothing); // name replaced by amount
  });

  testWidgets('Multi-category giving sums the basket (1000 + 500 + 200 = 1700)', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final basket = container.read(basketProvider.notifier);
    basket.setAmount('tithe', 1000);
    basket.setAmount('conference_evangelism', 500);
    basket.setAmount('church_building', 200);
    await tester.pumpAndSettle();

    expect(container.read(basketProvider).total, 1700);
    expect(find.text('KSh 1700.00'), findsOneWidget);
  });
}
