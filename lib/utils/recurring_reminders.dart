import '../models/recurring_transaction.dart';

const int recurringReminderLeadDays = 2;

class RecurringReminder {
  final RecurringTransaction schedule;

  // Negative when overdue, 0 when due today.
  final int daysUntilDue;

  const RecurringReminder({required this.schedule, required this.daysUntilDue});

  bool get isOverdue => daysUntilDue < 0;
}

/// Active schedules that are overdue, due today, or due within [leadDays],
/// ordered by due date.
List<RecurringReminder> upcomingRecurringReminders(
  List<RecurringTransaction> schedules, {
  DateTime? now,
  int leadDays = recurringReminderLeadDays,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);

  final reminders = <RecurringReminder>[];
  for (final schedule in schedules) {
    if (!schedule.isActive) continue;
    final due = DateTime(
      schedule.nextDueDate.year,
      schedule.nextDueDate.month,
      schedule.nextDueDate.day,
    );
    // Compare calendar days through UTC so DST changes cannot skew the count.
    final days = DateTime.utc(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    if (days <= leadDays) {
      reminders.add(RecurringReminder(schedule: schedule, daysUntilDue: days));
    }
  }

  reminders.sort((a, b) {
    final byDays = a.daysUntilDue.compareTo(b.daysUntilDue);
    return byDays != 0
        ? byDays
        : a.schedule.name.toLowerCase().compareTo(
            b.schedule.name.toLowerCase(),
          );
  });
  return reminders;
}

String reminderDueText(int daysUntilDue) {
  if (daysUntilDue < 0) {
    final days = -daysUntilDue;
    return days == 1 ? 'Overdue by 1 day' : 'Overdue by $days days';
  }
  if (daysUntilDue == 0) return 'Due today';
  if (daysUntilDue == 1) return 'Due tomorrow';
  return 'Due in $daysUntilDue days';
}
