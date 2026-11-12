import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/expense_category.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/budget_calculator.dart';
import '../utils/transaction_helpers.dart';
import '../widgets/budget_card.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  Future<void> _showBudgetDialog({Budget? budget}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _BudgetDialog(budget: budget),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            budget == null ? 'Budget saved successfully' : 'Budget updated',
          ),
        ),
      );
    }
  }

  Future<void> _deleteBudget(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete budget?'),
        content: const Text(
          'This budget will be removed. Your transactions will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(budgetProvider.notifier).deleteBudget(budget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Budget deleted')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not delete budget')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetProvider);
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add budget'),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Could not load budgets')),
        data: (budgets) => transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('Could not load transactions')),
          data: (transactions) {
            final yearOptions = {
              DateTime.now().year,
              selectedYear,
              ...budgets.map((budget) => budget.year),
            }.toList()..sort();
            final periodBudgets = budgets
                .where(
                  (budget) =>
                      budget.year == selectedYear &&
                      budget.month == selectedMonth,
                )
                .toList();
            final spendingByBudget = {
              for (final budget in periodBudgets)
                budget.id: calculateCategorySpending(
                  transactions: transactions,
                  category: budget.category,
                  year: budget.year,
                  month: budget.month,
                ),
            };
            final totalBudget = periodBudgets.fold<double>(
              0,
              (total, budget) => total + budget.monthlyLimit,
            );
            final totalSpent = spendingByBudget.values.fold<double>(
              0,
              (total, amount) => total + amount,
            );
            final exceededCount = periodBudgets
                .where(
                  (budget) =>
                      (spendingByBudget[budget.id] ?? 0) > budget.monthlyLimit,
                )
                .length;
            final sortedBudgets = [...periodBudgets]
              ..sort((a, b) {
                final spentA = spendingByBudget[a.id] ?? 0;
                final spentB = spendingByBudget[b.id] ?? 0;
                final exceededA = spentA > a.monthlyLimit;
                final exceededB = spentB > b.monthlyLimit;

                if (exceededA != exceededB) {
                  return exceededA ? -1 : 1;
                }

                final ratioA = a.monthlyLimit > 0
                    ? spentA / a.monthlyLimit
                    : 0.0;
                final ratioB = b.monthlyLimit > 0
                    ? spentB / b.monthlyLimit
                    : 0.0;

                return ratioB.compareTo(ratioA);
              });

            return SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedMonth,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: List.generate(
                            12,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text(monthNames[index]),
                            ),
                          ),
                          onChanged: (month) {
                            if (month != null) {
                              setState(() => selectedMonth = month);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedYear,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: yearOptions
                              .map(
                                (year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                ),
                              )
                              .toList(),
                          onChanged: (year) {
                            if (year != null) {
                              setState(() => selectedYear = year);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BudgetOverview(
                    monthName: monthNames[selectedMonth - 1],
                    year: selectedYear,
                    totalBudget: totalBudget,
                    totalSpent: totalSpent,
                    exceededCount: exceededCount,
                  ),
                  const SizedBox(height: 16),
                  if (sortedBudgets.isEmpty)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No budgets for this month',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create a budget to start tracking your spending.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _showBudgetDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add budget'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final budget in sortedBudgets) ...[
                      BudgetCard(
                        budget: budget,
                        amountSpent: spendingByBudget[budget.id] ?? 0,
                        onEdit: () => _showBudgetDialog(budget: budget),
                        onDelete: () => _deleteBudget(budget),
                      ),
                      const SizedBox(height: 16),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BudgetOverview extends StatelessWidget {
  final String monthName;
  final int year;
  final double totalBudget;
  final double totalSpent;
  final int exceededCount;

  const _BudgetOverview({
    required this.monthName,
    required this.year,
    required this.totalBudget,
    required this.totalSpent,
    required this.exceededCount,
  });

  String _currency(double value) => '₹${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final remaining = totalBudget - totalSpent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text('$monthName $year'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    title: 'Total budget',
                    value: _currency(totalBudget),
                  ),
                ),
                Expanded(
                  child: _OverviewMetric(
                    title: 'Total spent',
                    value: _currency(totalSpent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    title: remaining >= 0 ? 'Remaining' : 'Over budget',
                    value: _currency(remaining.abs()),
                  ),
                ),
                Expanded(
                  child: _OverviewMetric(
                    title: 'Budgets exceeded',
                    value: '$exceededCount',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String title;
  final String value;

  const _OverviewMetric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _BudgetDialog extends ConsumerStatefulWidget {
  final Budget? budget;

  const _BudgetDialog({this.budget});

  @override
  ConsumerState<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends ConsumerState<_BudgetDialog> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  late ExpenseCategory selectedCategory;
  late int selectedMonth;
  late int selectedYear;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    selectedCategory = budget?.category ?? ExpenseCategory.food;
    selectedMonth = budget?.month ?? DateTime.now().month;
    selectedYear = budget?.year ?? DateTime.now().year;
    if (budget != null) {
      amountController.text = budget.monthlyLimit.toString();
    }
  }

  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> saveBudget() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    final budget = Budget(
      id: widget.budget?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      category: selectedCategory,
      monthlyLimit: double.parse(amountController.text.trim()),
      year: selectedYear,
      month: selectedMonth,
    );

    try {
      final notifier = ref.read(budgetProvider.notifier);
      if (widget.budget == null) {
        await notifier.addBudget(budget);
      } else {
        await notifier.updateBudget(budget);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error is StateError
            ? error.message
            : 'Could not save budget';
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(11, (index) => currentYear - 5 + index);

    return AlertDialog(
      title: Text(widget.budget == null ? 'Add monthly budget' : 'Edit budget'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ExpenseCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(categoryDisplayName(category)),
                      ),
                    )
                    .toList(),
                onChanged: isSaving
                    ? null
                    : (category) {
                        if (category != null) {
                          setState(() => selectedCategory = category);
                        }
                      },
              ),
              TextFormField(
                controller: amountController,
                enabled: !isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monthly limit (₹)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a budget amount';
                  }

                  final amount = double.tryParse(value.trim());
                  if (amount == null || !amount.isFinite) {
                    return 'Enter a valid amount';
                  }

                  if (amount <= 0) {
                    return 'Budget must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: List.generate(
                        12,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text(monthNames[index]),
                        ),
                      ),
                      onChanged: isSaving
                          ? null
                          : (month) {
                              if (month != null) {
                                setState(() => selectedMonth = month);
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: years
                          .map(
                            (year) => DropdownMenuItem(
                              value: year,
                              child: Text('$year'),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (year) {
                              if (year != null) {
                                setState(() => selectedYear = year);
                              }
                            },
                    ),
                  ),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isSaving ? null : saveBudget,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.budget == null ? 'Save budget' : 'Update budget'),
        ),
      ],
    );
  }
}
