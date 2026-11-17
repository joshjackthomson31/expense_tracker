import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analytics_period.dart';
import '../models/expense_category.dart';
import '../models/payment_method.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/analytics_calculator.dart';
import '../utils/date_filter.dart';
import '../utils/date_formatter.dart';
import '../utils/transaction_helpers.dart';
import '../utils/spending_chart_calculator.dart';
import '../utils/transaction_calculator.dart';
import '../widgets/analytics_summary_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/monthly_spending_chart.dart';
import '../widgets/summary_card.dart';
import '../widgets/weekly_spending_chart.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod selectedPeriod = AnalyticsPeriod.thisMonth;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  DateTime selectedWeekStart = startOfWeek(DateTime.now());

  static const monthLabels = [
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

  static const categoryColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  Color colorForCategory(ExpenseCategory category) {
    return categoryColors[category.index % categoryColors.length];
  }

  List<Transaction> filterByPeriod(List<Transaction> transactions) {
    final now = DateTime.now();

    switch (selectedPeriod) {
      case AnalyticsPeriod.today:
        return filterTransactionsByDay(transactions, now);

      case AnalyticsPeriod.thisWeek:
        return filterTransactionsByWeek(transactions, selectedWeekStart);

      case AnalyticsPeriod.thisMonth:
        return filterTransactionsByYearMonth(
          transactions,
          selectedYear,
          selectedMonth,
        );
      case AnalyticsPeriod.allTime:
        return transactions;
    }
  }

  List<int> availableYears(List<Transaction> transactions) {
    final years = {
      DateTime.now().year,
      ...transactions.map((transaction) => transaction.date.year),
    }.toList()..sort();

    return years;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (transactions) {
        return _buildAnalytics(context, transactions);
      },
    );
  }

  Widget _buildAnalytics(BuildContext context, List<Transaction> transactions) {
    final filteredTransactions = filterByPeriod(transactions);

    final periodSelector = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<AnalyticsPeriod>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: AnalyticsPeriod.today, label: Text('Today')),
            ButtonSegment(value: AnalyticsPeriod.thisWeek, label: Text('Week')),
            ButtonSegment(
              value: AnalyticsPeriod.thisMonth,
              label: Text('Month'),
            ),
            ButtonSegment(
              value: AnalyticsPeriod.allTime,
              label: Text('All time'),
            ),
          ],

          selected: {selectedPeriod},

          onSelectionChanged: (selection) {
            setState(() {
              selectedPeriod = selection.first;
            });
          },
        ),
      ),
    );

    final yearOptions = {...availableYears(transactions), selectedYear}.toList()
      ..sort();

    final monthSelector = selectedPeriod == AnalyticsPeriod.thisMonth
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: selectedMonth,
                    isExpanded: true,

                    items: List.generate(12, (index) {
                      final month = index + 1;

                      return DropdownMenuItem(
                        value: month,
                        child: Text(monthLabels[index]),
                      );
                    }),

                    onChanged: (month) {
                      if (month == null) return;

                      setState(() {
                        selectedMonth = month;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    isExpanded: true,

                    items: yearOptions.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }).toList(),

                    onChanged: (year) {
                      if (year == null) return;

                      setState(() {
                        selectedYear = year;
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    if (filteredTransactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),

        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _sectionHeading(context, 'Reporting Period'),
              periodSelector,
              monthSelector,
              if (selectedPeriod == AnalyticsPeriod.thisWeek)
                _buildWeekSelector(context),
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No data for this period',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try selecting a different reporting period.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              if (selectedPeriod == AnalyticsPeriod.thisWeek) ...[
                const SizedBox(height: 24),
                _buildWeeklySpending(context, transactions),
              ],
            ],
          ),
        ),
      );
    }

    final totalExpenses = calculateTotalExpense(filteredTransactions);
    final totalIncome = calculateTotalIncome(filteredTransactions);
    final balance = calculateBalance(filteredTransactions);
    final savingsRate = calculateSavingsRate(filteredTransactions);

    final selectedDate = DateTime(selectedYear, selectedMonth);
    final currentMonthExpenses = getMonthlyExpenses(
      transactions,
      selectedYear,
      selectedMonth,
    );
    final previousMonthDate = DateTime(selectedYear, selectedMonth - 1);
    final previousMonthExpenses = getMonthlyExpenses(
      transactions,
      previousMonthDate.year,
      previousMonthDate.month,
    );
    final expenseChange = calculatePercentageChange(
      currentMonthExpenses,
      previousMonthExpenses,
    );

    final expensesByCategory = calculateExpensesByCategory(
      filteredTransactions,
    );

    final categoryTotals = ExpenseCategory.values
        .where((category) => (expensesByCategory[category] ?? 0) > 0)
        .map((category) => MapEntry(category, expensesByCategory[category]!))
        .toList();

    final paymentMethodTotals = PaymentMethod.values
        .map((method) {
          return MapEntry(
            method,
            calculatePaymentMethodTotal(filteredTransactions, method),
          );
        })
        .where((entry) => entry.value > 0)
        .toList();

    final monthlySpending = calculateMonthlySpending(
      transactions,
      selectedDate,
      6,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),

      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _sectionHeading(context, 'Reporting Period'),
            periodSelector,
            monthSelector,
            if (selectedPeriod == AnalyticsPeriod.thisWeek)
              _buildWeekSelector(context),

            const SizedBox(height: 24),
            _sectionHeading(context, 'Financial Summary'),
            const SizedBox(height: 4),
            Text(switch (selectedPeriod) {
              AnalyticsPeriod.today => 'Today',
              AnalyticsPeriod.thisWeek => 'Selected week',
              AnalyticsPeriod.thisMonth =>
                '${monthLabels[selectedMonth - 1]} $selectedYear',
              AnalyticsPeriod.allTime => 'All time',
            }),
            const SizedBox(height: 12),

            BalanceCard(balance: balance, title: 'Period balance'),

            const SizedBox(height: 16),

            _ResponsiveSummary(
              children: [
                SummaryCard(
                  title: 'Income',
                  amount: totalIncome,
                  icon: Icons.arrow_downward,
                  iconColor: Colors.green,
                ),
                SummaryCard(
                  title: 'Expenses',
                  amount: totalExpenses,
                  icon: Icons.arrow_upward,
                  iconColor: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _ResponsiveSummary(
              children: [
                AnalyticsSummaryCard(
                  title: 'Savings Rate',
                  value: '${savingsRate.toStringAsFixed(1)}%',
                  icon: Icons.savings,
                ),
                if (selectedPeriod == AnalyticsPeriod.thisMonth)
                  AnalyticsSummaryCard(
                    title: 'Expenses vs Last Month',
                    value: expenseChange == null
                        ? 'No previous data'
                        : '${expenseChange >= 0 ? '+' : ''}'
                              '${expenseChange.toStringAsFixed(1)}%',
                    icon: Icons.compare_arrows,
                  ),
              ],
            ),

            if (selectedPeriod == AnalyticsPeriod.thisWeek) ...[
              const SizedBox(height: 24),
              _buildWeeklySpending(context, transactions),
            ],
            if (selectedPeriod == AnalyticsPeriod.thisMonth ||
                selectedPeriod == AnalyticsPeriod.allTime) ...[
              const SizedBox(height: 24),
              Text(
                'Monthly Spending Trend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _ChartViewport(
                child: MonthlySpendingChart(monthlySpending: monthlySpending),
              ),
            ],

            const SizedBox(height: 24),

            _sectionHeading(context, 'Spending by Category'),
            const SizedBox(height: 12),

            if (categoryTotals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No spending data for this period.')),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final diameter = constraints.maxWidth.clamp(0.0, 300.0);
                  return SizedBox(
                    height: diameter,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: diameter * 0.12,
                        sections: categoryTotals.map((entry) {
                          final percentage =
                              (entry.value / totalExpenses) * 100;
                          return PieChartSectionData(
                            value: entry.value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            color: colorForCategory(entry.key),
                            radius: diameter * 0.3,
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Text(
                'By Category',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              for (final entry in categoryTotals)
                ListTile(
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: colorForCategory(entry.key),
                  ),

                  title: Text(categoryDisplayName(entry.key)),

                  subtitle: Text(
                    '${((entry.value / totalExpenses) * 100).toStringAsFixed(0)}'
                    '% of total spending',
                  ),

                  trailing: Text(
                    '₹${entry.value.toStringAsFixed(2)}',

                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],

            const SizedBox(height: 24),

            _sectionHeading(context, 'By Payment Method'),

            const SizedBox(height: 8),

            for (final entry in paymentMethodTotals)
              ListTile(
                title: Text(paymentMethodDisplayName(entry.key)),

                subtitle: Text(
                  '${((entry.value / totalExpenses) * 100).toStringAsFixed(0)}'
                  '% of total spending',
                ),

                trailing: Text(
                  '₹${entry.value.toStringAsFixed(2)}',

                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  void _changeWeek(int offset) {
    final next = DateTime(
      selectedWeekStart.year,
      selectedWeekStart.month,
      selectedWeekStart.day + offset * 7,
    );
    if (next.isAfter(startOfWeek(DateTime.now()))) return;
    setState(() {
      selectedWeekStart = next;
    });
  }

  Widget _buildWeekSelector(BuildContext context) {
    final weekEnd = DateTime(
      selectedWeekStart.year,
      selectedWeekStart.month,
      selectedWeekStart.day + 6,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${formatDate(selectedWeekStart)} - ${formatDate(weekEnd)}',
          key: const Key('weekly-spending-date-range'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'All figures below use this week and the selected expense dates.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Previous week',
              onPressed: () => _changeWeek(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => setState(() {
                  selectedWeekStart = startOfWeek(DateTime.now());
                }),
                child: const Text('This week', textAlign: TextAlign.center),
              ),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: selectedWeekStart.isBefore(startOfWeek(DateTime.now()))
                  ? () => _changeWeek(1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklySpending(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    final dailySpending = calculateWeeklySpending(
      transactions,
      selectedWeekStart,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Weekly Spending', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (dailySpending.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No expenses for this week.'),
          ),
        _ChartViewport(
          child: WeeklySpendingChart(
            dailySpending: dailySpending,
            weekStart: selectedWeekStart,
          ),
        ),
      ],
    );
  }
}

class _ResponsiveSummary extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveSummary({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.length == 1) return children.single;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 350 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [children[0], const SizedBox(height: 12), children[1]],
          );
        }
        return Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 12),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }
}

class _ChartViewport extends StatelessWidget {
  final Widget child;

  const _ChartViewport({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep axis labels readable on narrow screens without overflowing the page.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 360 ? 360 : constraints.maxWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 24, 16),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
