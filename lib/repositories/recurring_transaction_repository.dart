import '../models/recurring_transaction.dart';

abstract class RecurringTransactionRepository {
  Future<void> saveRecurringTransaction(RecurringTransaction recurring);
  Future<List<RecurringTransaction>> getRecurringTransactions();
  Future<void> updateRecurringTransaction(RecurringTransaction recurring);
  Future<void> deleteRecurringTransaction(String id);
}
