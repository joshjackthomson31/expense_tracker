import 'package:hive/hive.dart';

import '../models/budget.dart';
import 'budget_repository.dart';

class HiveBudgetRepository implements BudgetRepository {
  static const String boxName = 'budgets';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }

    return Hive.openBox(boxName);
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    final box = await _openBox();
    await box.put(budget.id, budget.toMap());
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    final box = await _openBox();
    await box.put(budget.id, budget.toMap());
  }

  @override
  Future<List<Budget>> getBudgets() async {
    final box = await _openBox();

    return box.values
        .map((data) => Budget.fromMap(Map<String, dynamic>.from(data as Map)))
        .toList();
  }

  @override
  Future<void> deleteBudget(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
