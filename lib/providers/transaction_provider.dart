import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../repositories/hive_transaction_repository.dart';
import '../repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return HiveTransactionRepository();
});

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final repository = ref.read(transactionRepositoryProvider);

    return await repository.getTransactions();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final repository = ref.read(transactionRepositoryProvider);

    await repository.saveTransaction(transaction);

    final currentTransactions = state.value ?? [];

    state = AsyncData([...currentTransactions, transaction]);
  }

  Future<void> updateTransaction(Transaction updatedTransaction) async {
    final repository = ref.read(transactionRepositoryProvider);

    await repository.updateTransaction(updatedTransaction);

    final currentTransactions = state.value ?? [];

    state = AsyncData([
      for (final transaction in currentTransactions)
        if (transaction.id == updatedTransaction.id)
          updatedTransaction
        else
          transaction,
    ]);
  }

  Future<void> deleteTransaction(String id) async {
    final repository = ref.read(transactionRepositoryProvider);

    await repository.deleteTransaction(id);

    final currentTransactions = state.value ?? [];

    state = AsyncData(
      currentTransactions.where((transaction) => transaction.id != id).toList(),
    );
  }
}

final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
      TransactionNotifier.new,
    );
