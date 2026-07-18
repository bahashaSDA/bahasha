import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import 'package:bahasha/core/data/local_database.dart';
import 'package:bahasha/core/providers.dart';
import 'package:bahasha/core/theme/app_theme.dart';
import 'package:bahasha/features/history/domain/contribution_view.dart';
import 'package:bahasha/features/history/presentation/history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ContributionView parses allocations and builds shareable text', () {
    final row = Contribution(
      id: 'abcdef12-0000-0000-0000-000000000000',
      churchId: 'c1',
      totalAmount: 1700,
      allocationsJson:
          '[{"categoryCode":"tithe","amount":1000},{"categoryCode":"church_building","amount":700}]',
      anonymous: false,
      status: 'completed',
      counter: 1,
      nonce: 'n',
      signature: 's',
      failureReason: null,
      retryCount: 0,
      createdAt: DateTime(2026, 7, 18, 10, 30),
      updatedAt: DateTime(2026, 7, 18, 10, 30),
    );
    final view = ContributionView(row);
    expect(view.allocations.length, 2);
    expect(view.statusChip.label, 'Completed');
    // The share text is a human-readable receipt with the categories and total.
    expect(view.shareText, contains("God's Tithe"));
    expect(view.shareText, contains('Church Building'));
    expect(view.shareText, contains('Total: KSh 1,700'));
    expect(view.shareText, contains('Ref: ABCDEF12'));
  });

  testWidgets('History renders a stored contribution', (tester) async {
    final db = LocalDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.contributions).insert(
          ContributionsCompanion(
            id: const Value('abcdef12-0000-0000-0000-000000000000'),
            churchId: const Value('c1'),
            totalAmount: const Value(1700),
            allocationsJson: const Value('[{"categoryCode":"tithe","amount":1700}]'),
            counter: const Value(1),
            status: const Value('completed'),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.light(), home: const HistoryScreen()),
      ),
    );
    // Pump fixed frames rather than pumpAndSettle: the loading spinner animates
    // indefinitely, so pumpAndSettle would never return before the stream emits.
    await tester.pump(); // build
    await tester.pump(const Duration(milliseconds: 100)); // stream emits

    expect(find.text('Your giving'), findsOneWidget);
    expect(find.textContaining('1,700'), findsWidgets); // amount shown
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('History shows the empty state with no contributions', (tester) async {
    final db = LocalDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.light(), home: const HistoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No contributions yet'), findsOneWidget);
  });
}
