import '../models/expense_category.dart';
import '../models/payment_method.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';

double calculateTotalIncome(List<Transaction> transactions) {
  return transactions
      .where((transaction) => transaction.type == TransactionType.income)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);
}

double calculateTotalExpense(List<Transaction> transactions) {
  return transactions
      .where((transaction) => transaction.type == TransactionType.expense)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);
}

/// Tracked in-app balance, not the user's real bank balance.
double calculateBalance(List<Transaction> transactions) {
  final income = calculateTotalIncome(transactions);
  final expenses = calculateTotalExpense(transactions);

  return income - expenses;
}

/// Percentage of income remaining after expenses. Returns 0 when there's no
/// income, since the ratio is undefined rather than meaningfully zero.
double calculateSavingsRate(List<Transaction> transactions) {
  final income = calculateTotalIncome(transactions);
  final expenses = calculateTotalExpense(transactions);

  if (income == 0) {
    return 0;
  }

  return ((income - expenses) / income) * 100;
}

double calculateCategoryPercentage({
  required double categoryAmount,
  required double totalExpenses,
}) {
  if (totalExpenses == 0) {
    return 0;
  }

  return (categoryAmount / totalExpenses) * 100;
}

double calculateCategoryTotal(
  List<Transaction> transactions,
  ExpenseCategory category,
) {
  return transactions
      .where(
        (transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.expenseCategory == category,
      )
      .fold(0.0, (sum, transaction) => sum + transaction.amount);
}

/// Single-pass category breakdown, suitable for feeding charts.
Map<ExpenseCategory, double> calculateExpensesByCategory(
  List<Transaction> transactions,
) {
  final result = <ExpenseCategory, double>{};

  for (final transaction in transactions) {
    if (transaction.type != TransactionType.expense) {
      continue;
    }

    final category = transaction.expenseCategory;

    if (category == null) {
      continue;
    }

    result[category] = (result[category] ?? 0) + transaction.amount;
  }

  return result;
}

double calculatePaymentMethodTotal(
  List<Transaction> transactions,
  PaymentMethod method,
) {
  return transactions
      .where(
        (transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.paymentMethod == method,
      )
      .fold(0.0, (sum, transaction) => sum + transaction.amount);
}
