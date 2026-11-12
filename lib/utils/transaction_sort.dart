import '../models/transaction.dart';
import '../models/transaction_sort.dart';

void sortTransactions(List<Transaction> transactions, TransactionSort sort) {
  switch (sort) {
    case TransactionSort.newest:
      transactions.sort((a, b) => b.date.compareTo(a.date));

    case TransactionSort.oldest:
      transactions.sort((a, b) => a.date.compareTo(b.date));

    case TransactionSort.amountHighToLow:
      transactions.sort((a, b) => b.amount.compareTo(a.amount));

    case TransactionSort.amountLowToHigh:
      transactions.sort((a, b) => a.amount.compareTo(b.amount));
  }
}
