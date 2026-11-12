import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows the Expense Tracker home screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            _FakeTransactionRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('No transactions yet'), 300);

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Add transaction'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 800), const Size(402, 874)]) {
    testWidgets('Home add action never overlaps content at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(
              _FakeTransactionRepository(),
            ),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      final list = find.byType(ListView);
      final addButton = find.byType(FloatingActionButton);
      void expectSeparateAreas() {
        expect(
          tester.getRect(list).bottom,
          lessThanOrEqualTo(tester.getRect(addButton).top),
        );
        expect(addButton.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      expectSeparateAreas();
      await tester.drag(list, const Offset(0, -250));
      await tester.pumpAndSettle();
      expectSeparateAreas();
      await tester.scrollUntilVisible(
        find.widgetWithText(OutlinedButton, 'Add transaction'),
        150,
      );
      await tester.pumpAndSettle();
      expectSeparateAreas();
      expect(find.text('No transactions yet').hitTestable(), findsOneWidget);
      expect(
        find
            .text('Add your first transaction to start tracking your finances.')
            .hitTestable(),
        findsOneWidget,
      );

      await tester.tap(addButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Add Expense'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expectSeparateAreas();
    });
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    return List.of(_transactions);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index >= 0) {
      _transactions[index] = transaction;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((transaction) => transaction.id == id);
  }

  @override
  Future<void> clearAllTransactions() async {
    _transactions.clear();
  }
}
