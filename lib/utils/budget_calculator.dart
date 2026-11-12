import '../models/expense_category.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';

bool budgetAlreadyExists({
  required List<Budget> budgets,
  required Budget candidate,
  String? excludeBudgetId,
}) {
  return budgets.any(
    (budget) =>
        budget.id != excludeBudgetId &&
        budget.category == candidate.category &&
        budget.year == candidate.year &&
        budget.month == candidate.month,
  );
}

double calculateRemainingBudget({
  required double budgetLimit,
  required double amountSpent,
}) {
  return budgetLimit - amountSpent;
}

double calculateBudgetPercentage({
  required double budgetLimit,
  required double amountSpent,
}) {
  if (budgetLimit <= 0) {
    return 0;
  }

  return (amountSpent / budgetLimit) * 100;
}

double calculateCategorySpending({
  required List<Transaction> transactions,
  required ExpenseCategory category,
  required int year,
  required int month,
}) {
  return transactions
      .where(
        (transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.expenseCategory == category &&
            transaction.date.year == year &&
            transaction.date.month == month,
      )
      .fold(0.0, (total, transaction) => total + transaction.amount);
}

String getBudgetStatus({
  required double amountSpent,
  required double budgetLimit,
}) {
  if (budgetLimit <= 0) {
    return 'Invalid budget limit';
  }

  if (amountSpent > budgetLimit) {
    return 'Budget exceeded';
  }

  if (amountSpent >= budgetLimit * 0.8) {
    return 'Approaching budget limit';
  }

  return 'Within budget';
}
