import 'package:hive/hive.dart';

import '../models/transaction.dart';
import 'transaction_repository.dart';

class HiveTransactionRepository implements TransactionRepository {
  static const String boxName = 'transactions';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }

    return await Hive.openBox(boxName);
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final box = await _openBox();

    await box.put(transaction.id, transaction.toMap());
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    final box = await _openBox();

    return box.values.map((data) {
      return Transaction.fromMap(Map<String, dynamic>.from(data));
    }).toList();
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final box = await _openBox();

    await box.put(transaction.id, transaction.toMap());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final box = await _openBox();

    await box.delete(id);
  }

  @override
  Future<void> clearAllTransactions() async {
    final box = await _openBox();

    await box.clear();
  }
}
