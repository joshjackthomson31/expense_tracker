import 'package:expense_tracker/models/analytics_period.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/income_category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/utils/date_filter.dart';
import 'package:expense_tracker/utils/date_formatter.dart';
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
    double height = 800,
  }) async {
    tester.view.physicalSize = Size(320, height);
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

  testWidgets('All time combines months and years without duplicate totals', (
    tester,
  ) async {
    await showAnalytics(tester, [
      transaction('Current income', 1000, income: true),
      transaction('Current expense', 200),
      transaction(
        'Historical income',
        3000,
        income: true,
        date: DateTime(now.year - 1, now.month, 15),
      ),
      transaction(
        'Historical expense',
        500,
        date: DateTime(now.year, now.month - 1, 15),
      ),
    ], textScale: 1.5);
    expect(tester.widget<BalanceCard>(find.byType(BalanceCard)).balance, 800);
    await tester.ensureVisible(find.text('All time'));
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(find.byType(BalanceCard), findsOneWidget);
    expect(tester.widget<BalanceCard>(find.byType(BalanceCard)).balance, 3300);
    expect(
      tester
          .widgetList<SummaryCard>(find.byType(SummaryCard))
          .map((card) => card.amount),
      [4000, 700],
    );
    expect(find.text('Expenses vs Last Month'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Month'));
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(tester.widget<BalanceCard>(find.byType(BalanceCard)).balance, 800);
    expect(find.byType(DropdownButton<int>), findsNWidgets(2));
  });

  testWidgets('historical year selection changes the monthly summary', (
    tester,
  ) async {
    await showAnalytics(tester, [
      transaction('Current', 100),
      transaction(
        'Last year',
        700,
        date: DateTime(now.year - 1, now.month, 15),
      ),
    ]);
    await tester.tap(find.byType(DropdownButton<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('${now.year - 1}').last);
    await tester.pumpAndSettle();
    expect(tester.widget<BalanceCard>(find.byType(BalanceCard)).balance, -700);
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
    await tester.ensureVisible(find.text('Month'));
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

  testWidgets(
    'weekly navigation updates cards, category totals and bars together',
    (tester) async {
      final monday = startOfWeek(now);
      final lastMonday = DateTime(monday.year, monday.month, monday.day - 7);
      final lastWednesday = DateTime(
        lastMonday.year,
        lastMonday.month,
        lastMonday.day + 2,
      );
      await showAnalytics(
        tester,
        [
          transaction('Current expense', 100),
          transaction('Late entry for Wednesday', 300, date: lastWednesday),
        ],
        textScale: 1.5,
        height: 4000,
      );
      expect(find.byType(WeeklySpendingChart), findsNothing);
      expect(find.byTooltip('Previous week'), findsNothing);
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.byType(MonthlySpendingChart), findsNothing);

      Future<void> press(String tooltip) async {
        await tester.scrollUntilVisible(
          find.byTooltip(tooltip),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.byTooltip(tooltip));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(tooltip));
        await tester.pumpAndSettle();
      }

      await press('Previous week');
      var chart = tester.widget<WeeklySpendingChart>(
        find.byType(WeeklySpendingChart),
      );
      expect(chart.weekStart, lastMonday);
      expect(chart.dailySpending, {lastWednesday: 300.0});
      expect(
        tester.widget<BalanceCard>(find.byType(BalanceCard)).balance,
        -300,
      );
      expect(
        tester
            .widgetList<SummaryCard>(find.byType(SummaryCard))
            .map((c) => c.amount),
        [0, 300],
      );
      await tester.scrollUntilVisible(
        find.byType(PieChart),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PieChart>(find.byType(PieChart))
            .data
            .sections
            .single
            .value,
        300,
      );
      final range = tester.widget<Text>(
        find.byKey(const Key('weekly-spending-date-range')),
      );
      final lastSunday = DateTime(
        lastMonday.year,
        lastMonday.month,
        lastMonday.day + 6,
      );
      expect(
        range.data,
        '${formatDate(lastMonday)} - ${formatDate(lastSunday)}',
      );
      expect(tester.takeException(), isNull);

      await press('Next week');
      chart = tester.widget<WeeklySpendingChart>(
        find.byType(WeeklySpendingChart),
      );
      expect(chart.weekStart, monday);
      expect(chart.dailySpending.values.fold(0.0, (a, b) => a + b), 100);

      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(nextButton.onPressed, isNull);
      expect(
        tester.widget<BalanceCard>(find.byType(BalanceCard)).balance,
        -100,
      );
      await press('Previous week');
      await tester.tap(find.text('This week'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<WeeklySpendingChart>(find.byType(WeeklySpendingChart))
            .weekStart,
        monday,
      );
      await tester.ensureVisible(find.text('Month'));
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.byType(WeeklySpendingChart), findsNothing);
      expect(find.byTooltip('Next week'), findsNothing);
      expect(find.byType(MonthlySpendingChart), findsOneWidget);
      await tester.ensureVisible(find.text('Today'));
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.byType(WeeklySpendingChart), findsNothing);
      expect(find.byType(MonthlySpendingChart), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'week navigation remains available in an empty reporting period',
    (tester) async {
      final monday = startOfWeek(now);
      final lastMonday = DateTime(monday.year, monday.month, monday.day - 7);
      await showAnalytics(tester, [
        transaction('Past expense', 250, date: lastMonday),
      ], height: 4000);
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('No data for this period'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byTooltip('Previous week'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
      final chart = tester.widget<WeeklySpendingChart>(
        find.byType(WeeklySpendingChart),
      );
      expect(chart.weekStart, lastMonday);
      expect(chart.dailySpending, {lastMonday: 250.0});
      expect(find.text('No data for this period'), findsNothing);
      expect(
        tester.widget<BalanceCard>(find.byType(BalanceCard)).balance,
        -250,
      );
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
      expect(find.text('No data for this period'), findsOneWidget);
      expect(find.byType(BalanceCard), findsNothing);
      expect(find.byType(PieChart), findsNothing);
      expect(find.byTooltip('Next week'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Transactions extends TransactionNotifier {
  final List<Transaction> transactions;

  _Transactions(this.transactions);

  @override
  Future<List<Transaction>> build() async => transactions;
}
