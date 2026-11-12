import '../models/budget.dart';

abstract class BudgetRepository {
  Future<void> saveBudget(Budget budget);

  Future<void> updateBudget(Budget budget);

  Future<List<Budget>> getBudgets();

  Future<void> deleteBudget(String id);
}
