import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/utils/date_filter.dart';
import 'package:expense_tracker/utils/spending_chart_calculator.dart';
import 'package:expense_tracker/widgets/weekly_spending_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction expense(String id, DateTime date, double amount) => Transaction(
  id: id,
  name: id,
  date: date,
  amount: amount,
  type: TransactionType.expense,
  paymentMethod: PaymentMethod.cash,
);

void main() {
  final monday = DateTime(2026, 12, 28);
  final expenses = [
    for (var day = 0; day < 7; day++)
      expense(
        // IDs reflect a later entry date; only the selected expense date matters.
        '${DateTime(2027, 1, 10).millisecondsSinceEpoch}-$day',
        DateTime(2026, 12, 28 + day, 23, 59),
        (day + 1) * 10,
      ),
    expense('before week', DateTime(2026, 12, 27, 23, 59), 1000),
    expense('next week', DateTime(2027, 1, 4), 2000),
    Transaction(
      id: 'income',
      name: 'Income',
      date: monday,
      amount: 5000,
      type: TransactionType.income,
      paymentMethod: PaymentMethod.cash,
    ),
  ];

  test('weekly totals use expense dates across a year boundary', () {
    final result = calculateWeeklySpending(expenses, DateTime(2027, 1, 3, 15));
    expect(startOfWeek(DateTime(2027, 1, 3, 15)), monday);
    expect(result, {
      for (var day = 0; day < 7; day++)
        DateTime(2026, 12, 28 + day): (day + 1) * 10.0,
    });
    expect(filterTransactionsByWeek(expenses, monday).length, 8);
  });

  for (final sunday in [DateTime(2026, 3, 8), DateTime(2026, 11, 1)]) {
    test('calendar week remains aligned across DST near $sunday', () {
      final start = startOfWeek(sunday);
      final days = [
        for (var day = 0; day < 7; day++)
          DateTime(start.year, start.month, start.day + day),
      ];
      final entries = [
        for (final day in days) expense(day.toIso8601String(), day, 10),
        expense(
          'following Monday',
          DateTime(start.year, start.month, start.day + 7),
          100,
        ),
      ];
      expect(start.weekday, DateTime.monday);
      expect(start.hour, 0);
      expect(calculateWeeklySpending(entries, sunday), {
        for (final day in days) day: 10.0,
      });
      expect(filterTransactionsByWeek(entries, sunday).length, 7);
    });
  }

  testWidgets('all seven weekday bars match the expense date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: WeeklySpendingChart(
              weekStart: monday,
              dailySpending: calculateWeeklySpending(expenses, monday),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final groups = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups;
    expect(groups.map((group) => group.x), [0, 1, 2, 3, 4, 5, 6]);
    expect(groups.map((group) => group.barRods.single.toY), [
      10,
      20,
      30,
      40,
      50,
      60,
      70,
    ]);
    for (final label in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
