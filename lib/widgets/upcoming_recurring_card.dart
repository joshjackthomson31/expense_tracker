import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_type.dart';
import '../providers/recurring_transaction_provider.dart';
import '../screens/recurring_transactions_screen.dart';
import '../utils/recurring_reminders.dart';

class UpcomingRecurringCard extends ConsumerWidget {
  const UpcomingRecurringCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(recurringTransactionProvider).value;
    if (schedules == null) return const SizedBox.shrink();

    final reminders = upcomingRecurringReminders(schedules);
    if (reminders.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final hasOverdue = reminders.any((reminder) => reminder.isOverdue);
    final background = hasOverdue
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = hasOverdue
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    final shown = reminders.take(3).toList();
    final extra = reminders.length - shown.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        container: true,
        label: 'Upcoming recurring payments',
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecurringTransactionsScreen(),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_repeat, color: foreground),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasOverdue
                              ? 'Recurring payments need attention'
                              : 'Upcoming recurring payments',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: foreground),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final reminder in shown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${reminder.schedule.name} · '
                              '${reminderDueText(reminder.daysUntilDue)}',
                              style: TextStyle(color: foreground),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${reminder.schedule.type == TransactionType.expense ? '−' : '+'}'
                            '₹${reminder.schedule.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (extra > 0)
                    Text('+$extra more', style: TextStyle(color: foreground)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
