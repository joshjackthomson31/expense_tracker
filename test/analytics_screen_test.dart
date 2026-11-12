import 'package:expense_tracker/models/analytics_period.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/income_category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/widgets/balance_card.dart';
import 'package:expense_tracker/widgets/monthly_spending_chart.dart';
import 'package:expense_tracker/widgets/summary_card.dart';
import 'package:expense_tracker/widgets/weekly_spending_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> showAnalytics(
    WidgetTester tester,
    List<Transaction> transactions, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionProvider.overrideWith(() => _Transactions(transactions)),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const AnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final now = DateTime.now();
  Transaction transaction(
    String id,
    double amount, {
    bool income = false,
    DateTime? date,
  }) => Transaction(
    id: id,
    name: id,
    amount: amount,
    type: income ? TransactionType.income : TransactionType.expense,
    expenseCategory: income ? null : ExpenseCategory.food,
    incomeCategory: income ? IncomeCategory.salary : null,
    date: date ?? now,
    paymentMethod: PaymentMethod.upi,
  );

  testWidgets('summary and all charts fit a narrow screen', (tester) async {
    await showAnalytics(tester, [
      transaction('Salary', 50000, income: true),
      transaction('Food', 3000),
    ]);
    expect(tester.widget<BalanceCard>(find.byType(BalanceCard)).balance, 47000);
    expect(
      tester
          .widgetList<SummaryCard>(find.byType(SummaryCard))
          .map((c) => c.amount),
      [50000, 3000],
    );

    for (final chart in [
      find.byType(WeeklySpendingChart),
      find.byType(MonthlySpendingChart),
      find.byType(PieChart),
    ]) {
      await tester.scrollUntilVisible(
        chart,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.scrollUntilVisible(
      find.text('By Payment Method'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('period controls remain usable in an empty period', (
    tester,
  ) async {
    await showAnalytics(tester, []);
    expect(find.text('No data for this period'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(
      tester
          .widget<SegmentedButton<AnalyticsPeriod>>(
            find.byType(SegmentedButton<AnalyticsPeriod>),
          )
          .selected,
      {AnalyticsPeriod.thisWeek},
    );
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('No data for this period'), findsOneWidget);
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<int>), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing month updates summary and empty state', (tester) async {
    final otherMonth = now.month == 12 ? 1 : now.month + 1;
    await showAnalytics(tester, [
      transaction('Current', 3000),
      transaction(
        'Other month',
        1000,
        date: DateTime(now.year, otherMonth, 15),
      ),
    ]);
    await tester.tap(find.byType(DropdownButton<int>).first);
    await tester.pumpAndSettle();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    await tester.ensureVisible(find.text(months[otherMonth - 1]).last);
    await tester.tap(find.text(months[otherMonth - 1]).last);
    await tester.pumpAndSettle();
    expect(tester.widget<BalanceCard>(find.byType(BalanceCard)).balance, -1000);
    await tester.tap(find.byType(DropdownButton<int>).first);
    await tester.pumpAndSettle();
    final emptyMonth = otherMonth == 12 ? 1 : otherMonth + 1;
    await tester.ensureVisible(find.text(months[emptyMonth - 1]).last);
    await tester.tap(find.text(months[emptyMonth - 1]).last);
    await tester.pumpAndSettle();
    expect(find.text('No data for this period'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('income-only period and large text do not break charts', (
    tester,
  ) async {
    await showAnalytics(tester, [
      transaction('Salary', 50000, income: true),
    ], textScale: 1.5);
    await tester.scrollUntilVisible(
      find.text('No spending data for this period.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PieChart), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _Transactions extends TransactionNotifier {
  final List<Transaction> transactions;

  _Transactions(this.transactions);

  @override
  Future<List<Transaction>> build() async => transactions;
}
