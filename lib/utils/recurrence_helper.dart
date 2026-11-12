import '../models/recurring_transaction.dart';

/// Calculates the next occurrence while preserving the preferred calendar day.
DateTime calculateNextDueDate({
  required DateTime currentDueDate,
  required RecurrenceFrequency frequency,
  required int preferredDay,
}) {
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return currentDueDate.add(const Duration(days: 1));
    case RecurrenceFrequency.weekly:
      return currentDueDate.add(const Duration(days: 7));
    case RecurrenceFrequency.monthly:
      return _nextMonthlyDate(currentDueDate, preferredDay);
    case RecurrenceFrequency.yearly:
      return _nextYearlyDate(currentDueDate, preferredDay);
  }
}

DateTime _nextMonthlyDate(DateTime current, int preferredDay) {
  final nextMonth = DateTime(current.year, current.month + 1);
  final daysInNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
  final actualDay = preferredDay.clamp(1, daysInNextMonth).toInt();

  return _withDate(current, nextMonth.year, nextMonth.month, actualDay);
}

DateTime _nextYearlyDate(DateTime current, int preferredDay) {
  final nextYear = current.year + 1;
  final isFebruary29 = current.month == 2 && preferredDay == 29;

  if (isFebruary29) {
    final isLeapYear =
        nextYear % 400 == 0 || (nextYear % 4 == 0 && nextYear % 100 != 0);

    return _withDate(current, nextYear, 2, isLeapYear ? 29 : 28);
  }

  final daysInMonth = DateTime(nextYear, current.month + 1, 0).day;
  final actualDay = preferredDay.clamp(1, daysInMonth).toInt();

  return _withDate(current, nextYear, current.month, actualDay);
}

DateTime _withDate(DateTime current, int year, int month, int day) {
  return DateTime(
    year,
    month,
    day,
    current.hour,
    current.minute,
    current.second,
    current.millisecond,
    current.microsecond,
  );
}

/// Creates a stable ID for one occurrence.
///
/// The existing key format is retained so previously recorded occurrences
/// continue to match after upgrading the app.
String createOccurrenceKey({
  required String recurringId,
  required DateTime dueDate,
}) {
  final dateKey =
      '${dueDate.year}-'
      '${dueDate.month.toString().padLeft(2, '0')}-'
      '${dueDate.day.toString().padLeft(2, '0')}';

  return '${recurringId}_$dateKey';
}
