import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/recurring_transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/utils/recurring_reminders.dart';
import 'package:expense_tracker/widgets/upcoming_recurring_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringTransaction _schedule(
  String name,
  DateTime due, {
  bool active = true,
}) {
  return RecurringTransaction(
    id: name,
    name: name,
    amount: 100,
    type: TransactionType.expense,
    expenseCategory: ExpenseCategory.bills,
    paymentMethod: PaymentMethod.upi,
    startDate: due,
    frequency: RecurrenceFrequency.monthly,
    isActive: active,
  );
}

class _Repo implements RecurringTransactionRepository {
  final List<RecurringTransaction> items;
  _Repo(this.items);

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() async => items;
  @override
  Future<void> saveRecurringTransaction(RecurringTransaction r) async {}
  @override
  Future<void> updateRecurringTransaction(RecurringTransaction r) async {}
  @override
  Future<void> deleteRecurringTransaction(String id) async {}
}

void main() {
  final now = DateTime(2026, 11, 13, 15, 30);

  test('reminders start 2 days before the due date', () {
    final reminders = upcomingRecurringReminders([
      _schedule('overdue', DateTime(2026, 11, 10)),
      _schedule('today', DateTime(2026, 11, 13)),
      _schedule('tomorrow', DateTime(2026, 11, 14)),
      _schedule('in two', DateTime(2026, 11, 15)),
      _schedule('in three', DateTime(2026, 11, 16)),
      _schedule('paused', DateTime(2026, 11, 14), active: false),
    ], now: now);

    expect(reminders.map((r) => r.schedule.name), [
      'overdue',
      'today',
      'tomorrow',
      'in two',
    ]);
    expect(reminders.map((r) => r.daysUntilDue), [-3, 0, 1, 2]);
  });

  test('reminder wording', () {
    expect(reminderDueText(-1), 'Overdue by 1 day');
    expect(reminderDueText(-3), 'Overdue by 3 days');
    expect(reminderDueText(0), 'Due today');
    expect(reminderDueText(1), 'Due tomorrow');
    expect(reminderDueText(2), 'Due in 2 days');
  });

  Future<void> pumpCard(WidgetTester tester, List<RecurringTransaction> items) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          recurringTransactionRepositoryProvider.overrideWithValue(
            _Repo(items),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: UpcomingRecurringCard()),
          ),
        ),
      ),
    );
  }

  testWidgets('card shows a due-soon schedule at 320px', (tester) async {
    final soon = DateTime.now().add(const Duration(days: 2));
    await pumpCard(tester, [
      _schedule('Rent with a very long descriptive name', soon),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Upcoming recurring payments'), findsOneWidget);
    expect(find.textContaining('Due in 2 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card is hidden when nothing is due soon', (tester) async {
    final later = DateTime.now().add(const Duration(days: 10));
    await pumpCard(tester, [_schedule('Gym', later)]);
    await tester.pumpAndSettle();

    expect(find.text('Upcoming recurring payments'), findsNothing);
  });
}
