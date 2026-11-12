import '../models/transaction.dart';
import '../models/transaction_type.dart';

double getMonthlyExpenses(List<Transaction> transactions, int year, int month) {
  return transactions
      .where(
        (transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.date.year == year &&
            transaction.date.month == month,
      )
      .fold(0.0, (total, transaction) => total + transaction.amount);
}

double? calculatePercentageChange(double current, double previous) {
  if (previous == 0) {
    return null;
  }

  return ((current - previous) / previous) * 100;
}
