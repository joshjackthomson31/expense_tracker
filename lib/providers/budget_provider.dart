import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../repositories/budget_repository.dart';
import '../repositories/hive_budget_repository.dart';
import '../utils/budget_calculator.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return HiveBudgetRepository();
});

class BudgetNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final repository = ref.read(budgetRepositoryProvider);
    return repository.getBudgets();
  }

  Future<void> addBudget(Budget budget) async {
    final currentBudgets = state.value ?? [];
    if (budgetAlreadyExists(budgets: currentBudgets, candidate: budget)) {
      throw StateError('A budget already exists for this category and month.');
    }

    final repository = ref.read(budgetRepositoryProvider);
    await repository.saveBudget(budget);
    state = AsyncData([...currentBudgets, budget]);
  }

  Future<void> updateBudget(Budget updatedBudget) async {
    final currentBudgets = state.value ?? [];
    if (budgetAlreadyExists(
      budgets: currentBudgets,
      candidate: updatedBudget,
      excludeBudgetId: updatedBudget.id,
    )) {
      throw StateError('A budget already exists for this category and month.');
    }

    if (!currentBudgets.any((budget) => budget.id == updatedBudget.id)) {
      throw StateError('Budget not found.');
    }

    final repository = ref.read(budgetRepositoryProvider);
    await repository.updateBudget(updatedBudget);

    state = AsyncData([
      for (final budget in currentBudgets)
        if (budget.id == updatedBudget.id) updatedBudget else budget,
    ]);
  }

  Future<void> deleteBudget(String id) async {
    final repository = ref.read(budgetRepositoryProvider);
    await repository.deleteBudget(id);

    final currentBudgets = state.value ?? [];
    state = AsyncData(
      currentBudgets.where((budget) => budget.id != id).toList(),
    );
  }
}

final budgetProvider = AsyncNotifierProvider<BudgetNotifier, List<Budget>>(
  BudgetNotifier.new,
);
