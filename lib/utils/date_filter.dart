import '../models/transaction.dart';

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

List<Transaction> filterTransactionsByDay(
  List<Transaction> transactions,
  DateTime day,
) {
  return transactions
      .where((transaction) => isSameDay(transaction.date, day))
      .toList();
}

List<Transaction> filterTransactionsByMonth(
  List<Transaction> transactions,
  DateTime date,
) {
  return transactions
      .where(
        (transaction) =>
            transaction.date.year == date.year &&
            transaction.date.month == date.month,
      )
      .toList();
}

List<Transaction> filterTransactionsByYearMonth(
  List<Transaction> transactions,
  int year,
  int month,
) {
  return transactions
      .where(
        (transaction) =>
            transaction.date.year == year && transaction.date.month == month,
      )
      .toList();
}

/// Monday-based, with the time component stripped so hours never shift the week.
DateTime startOfWeek(DateTime date) {
  return DateTime(date.year, date.month, date.day - (date.weekday - 1));
}

List<Transaction> filterTransactionsByWeek(
  List<Transaction> transactions,
  DateTime date,
) {
  final start = startOfWeek(date);
  final nextWeek = DateTime(start.year, start.month, start.day + 7);

  return transactions.where((transaction) {
    return !transaction.date.isBefore(start) &&
        transaction.date.isBefore(nextWeek);
  }).toList();
}

/// Inclusive of both [startDate] and [endDate], regardless of their time
/// component (so a transaction later on [endDate] is still included).
List<Transaction> filterTransactionsByDateRange(
  List<Transaction> transactions,
  DateTime startDate,
  DateTime endDate,
) {
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final endExclusive = DateTime(
    endDate.year,
    endDate.month,
    endDate.day,
  ).add(const Duration(days: 1));

  return transactions.where((transaction) {
    return !transaction.date.isBefore(start) &&
        transaction.date.isBefore(endExclusive);
  }).toList();
}

/// Start of [date]'s month (inclusive) to the start of the next month
/// (exclusive), so every day in the month is covered regardless of time.
({DateTime start, DateTime end}) getMonthRange(DateTime date) {
  final start = DateTime(date.year, date.month);
  final end = DateTime(date.year, date.month + 1);

  return (start: start, end: end);
}
