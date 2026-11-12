import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recurring_transaction.dart';
import '../models/transaction_type.dart';
import '../providers/recurring_transaction_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/transaction_helpers.dart';
import 'add_recurring_transaction_screen.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  String _date(DateTime value) => formatDate(value);

  String _frequency(RecurrenceFrequency value) => switch (value) {
    RecurrenceFrequency.daily => 'Daily',
    RecurrenceFrequency.weekly => 'Weekly',
    RecurrenceFrequency.monthly => 'Monthly',
    RecurrenceFrequency.yearly => 'Yearly',
  };

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction recurring,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text(
          'Delete the recurring schedule for "${recurring.name}"? Existing transactions will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(recurringTransactionProvider.notifier)
          .deleteRecurringTransaction(recurring.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete schedule.')),
        );
      }
    }
  }

  Future<void> _add(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AddRecurringTransactionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringTransactionProvider);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Add schedule'),
      ),
      body: SafeArea(
        top: false,
        child: recurringAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load recurring transactions: $error'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_repeat, size: 56),
                          SizedBox(height: 12),
                          Text(
                            'No recurring schedules yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add rent, subscriptions, salary, or other repeating transactions.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            final sorted = [...items]
              ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = sorted[index];
                final isDue = !DateTime(
                  item.nextDueDate.year,
                  item.nextDueDate.month,
                  item.nextDueDate.day,
                ).isAfter(todayOnly);
                final isExpense = item.type == TransactionType.expense;
                final category = isExpense
                    ? item.expenseCategory == null
                          ? 'Uncategorized'
                          : categoryDisplayName(item.expenseCategory!)
                    : item.incomeCategory == null
                    ? 'Uncategorized'
                    : incomeCategoryDisplayName(item.incomeCategory!);
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              child: Icon(
                                isExpense
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_frequency(item.frequency)} · $category',
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Next due: ${_date(item.nextDueDate)}'),
                                  if (isDue && item.isActive)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        'Due now',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${isExpense ? '−' : '+'}₹${item.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpense
                                ? Theme.of(context).colorScheme.error
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              item.isActive
                                  ? Icons.check_circle_outline
                                  : Icons.pause_circle_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.isActive ? 'Active' : 'Paused',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(
                                        recurringTransactionProvider.notifier,
                                      )
                                      .updateRecurringTransaction(
                                        item.copyWith(isActive: !item.isActive),
                                      );
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not update schedule.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: Icon(
                                item.isActive ? Icons.pause : Icons.play_arrow,
                              ),
                              label: Text(item.isActive ? 'Pause' : 'Resume'),
                            ),
                            if (isDue && item.isActive)
                              FilledButton.icon(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(
                                          recurringTransactionProvider.notifier,
                                        )
                                        .recordDueOccurrence(item);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Transaction recorded.',
                                              ),
                                            ),
                                          );
                                    }
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not record transaction: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Record payment'),
                              ),
                            if (isDue && item.isActive)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.history),
                                label: const Text('Catch Up'),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text(
                                        'Catch up overdue transactions?',
                                      ),
                                      content: const Text(
                                        'This will record every overdue occurrence '
                                        'up to today. Existing occurrences will not '
                                        'be duplicated.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
                                          child: const Text('Catch Up'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed != true || !context.mounted) {
                                    return;
                                  }

                                  try {
                                    final count = await ref
                                        .read(
                                          recurringTransactionProvider.notifier,
                                        )
                                        .catchUpOverdueOccurrences(item);

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$count overdue occurrence(s) processed.',
                                        ),
                                      ),
                                    );
                                  } catch (error) {
                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not catch up: $error',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        AddRecurringTransactionScreen(
                                          existingTransaction: item,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _confirmDelete(context, ref, item),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                        if (!item.isActive)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'Paused — no occurrence will be recorded until resumed.',
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
