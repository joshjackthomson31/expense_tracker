import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/recurring_transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/screens/add_recurring_transaction_screen.dart';
import 'package:expense_tracker/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final schedule = RecurringTransaction(
    id: 'rent',
    name: 'Rent with a long descriptive schedule name',
    amount: 15000,
    type: TransactionType.expense,
    expenseCategory: ExpenseCategory.bills,
    paymentMethod: PaymentMethod.upi,
    startDate: DateTime(2026, 1, 30),
    frequency: RecurrenceFrequency.monthly,
  );

  void narrowScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('schedule preview uses the existing end-of-month rule', (
    tester,
  ) async {
    narrowScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AddRecurringTransactionScreen(existingTransaction: schedule),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Following occurrence: 28 Feb 2026'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Next due: 30 Jan 2026'), findsOneWidget);
    expect(find.text('Schedule Anchor Date'), findsOneWidget);
    final dateTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Schedule Anchor Date'),
        matching: find.byType(ListTile),
      ),
    );
    expect(dateTile.onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings navigation, pause/resume, edit and delete still work', (
    tester,
  ) async {
    narrowScreen(tester);
    final repository = _RecurringRepository([schedule]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recurringTransactionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Indian Rupee (INR · ₹)'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Recurring Transactions'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly · Bills'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    expect(repository.items.single.isActive, isFalse);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Record payment'), findsNothing);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(repository.items.single.isActive, isTrue);
    expect(find.text('Record payment'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Edit'));
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Recurring Transaction'), findsOneWidget);
    expect(find.text(schedule.name), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.items, isEmpty);
    expect(find.text('No recurring schedules yet'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Track your money simply.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Track your money simply.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Version'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1.0.0 (build 1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _RecurringRepository implements RecurringTransactionRepository {
  final List<RecurringTransaction> items;

  _RecurringRepository(this.items);

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() async =>
      List.of(items);

  @override
  Future<void> saveRecurringTransaction(RecurringTransaction recurring) async {
    items.add(recurring);
  }

  @override
  Future<void> updateRecurringTransaction(
    RecurringTransaction recurring,
  ) async {
    items[items.indexWhere((item) => item.id == recurring.id)] = recurring;
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    items.removeWhere((item) => item.id == id);
  }
}
