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
  // A tall surface so the 420x912 design canvas lays out without clipping.
  binding() => TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home renders the Figma layout (title, rows, send bar)', (tester) async {
    binding();
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pump();

    // Focused title + fixed action + a couple of category row labels.
    expect(find.text('Tithe'), findsWidgets); // title (and possibly row 1)
    expect(find.text('Send contributions'), findsOneWidget);
    expect(find.text('Offering'), findsOneWidget);
  });

  testWidgets('Selecting a category shows its amount in the row', (tester) async {
    binding();
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());
    await tester.pump();

    final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    container.read(basketProvider.notifier).setAmount('tithe', 1000);
    await tester.pump();

    expect(find.text('1000.00'), findsOneWidget);
  });

  testWidgets('Multi-category giving sums the basket (1000 + 500 + 200 = 1700)', (tester) async {
    binding();
    await tester.pumpWidget(_wrap());
    await tester.pump();

    final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    final basket = container.read(basketProvider.notifier);
    basket.setAmount('tithe', 1000);
    basket.setAmount('conference_evangelism', 500);
    basket.setAmount('church_building', 200);
    await tester.pump();

    expect(container.read(basketProvider).total, 1700);
  });
}
