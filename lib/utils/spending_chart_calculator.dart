import '../models/transaction.dart';
import '../models/transaction_type.dart';
import 'date_filter.dart';

Map<DateTime, double> calculateDailySpending(
  List<Transaction> transactions,
  DateTime startDate,
  DateTime endDate,
) {
  final Map<DateTime, double> dailySpending = {};

  for (final transaction in transactions) {
    if (transaction.type != TransactionType.expense) {
      continue;
    }

    final day = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );

    if (day.isBefore(startDate) || !day.isBefore(endDate)) {
      continue;
    }

    dailySpending[day] = (dailySpending[day] ?? 0) + transaction.amount;
  }

  return dailySpending;
}

Map<DateTime, double> calculateWeeklySpending(
  List<Transaction> transactions,
  DateTime date,
) {
  final start = startOfWeek(date);
  final end = start.add(const Duration(days: 7));

  return calculateDailySpending(transactions, start, end);
}

List<DateTime> getLastSixMonths(DateTime selectedDate) {
  return List.generate(6, (index) {
    return DateTime(selectedDate.year, selectedDate.month - 5 + index);
  });
}

/// Totals expenses per month for the [monthsCount] months ending at
/// [referenceDate]'s month (inclusive), oldest first. Months with no
/// expenses still appear in the result with a total of 0.
Map<DateTime, double> calculateMonthlySpending(
  List<Transaction> transactions,
  DateTime referenceDate,
  int monthsCount,
) {
  final monthlySpending = <DateTime, double>{};

  final months = monthsCount == 6
      ? getLastSixMonths(referenceDate)
      : List.generate(monthsCount, (index) {
          return DateTime(
            referenceDate.year,
            referenceDate.month - (monthsCount - 1) + index,
          );
        });

  for (final monthKey in months) {
    monthlySpending[monthKey] = 0;
  }

  for (final transaction in transactions) {
    if (transaction.type != TransactionType.expense) {
      continue;
    }

    final monthKey = DateTime(transaction.date.year, transaction.date.month);

    if (monthlySpending.containsKey(monthKey)) {
      monthlySpending[monthKey] =
          monthlySpending[monthKey]! + transaction.amount;
    }
  }

  return monthlySpending;
}
