import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<void> saveTransaction(Transaction transaction);

  Future<List<Transaction>> getTransactions();

  Future<void> updateTransaction(Transaction transaction);

  Future<void> deleteTransaction(String id);

  Future<void> clearAllTransactions();
}
