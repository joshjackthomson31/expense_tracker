import 'package:hive/hive.dart';

import '../models/recurring_transaction.dart';
import 'recurring_transaction_repository.dart';

class HiveRecurringTransactionRepository
    implements RecurringTransactionRepository {
  static const String boxName = 'recurring_transactions';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return Hive.openBox(boxName);
  }

  @override
  Future<void> saveRecurringTransaction(RecurringTransaction recurring) async {
    final box = await _openBox();
    await box.put(recurring.id, recurring.toMap());
  }

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final box = await _openBox();
    return box.values
        .map(
          (value) => RecurringTransaction.fromMap(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> updateRecurringTransaction(
    RecurringTransaction recurring,
  ) async {
    final box = await _openBox();
    await box.put(recurring.id, recurring.toMap());
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
