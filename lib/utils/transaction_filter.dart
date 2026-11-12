import '../models/transaction.dart';
import '../models/transaction_filter.dart';
import '../models/transaction_type.dart';

List<Transaction> filterTransactions(
  List<Transaction> transactions,
  TransactionFilter filter,
) {
  switch (filter) {
    case TransactionFilter.all:
      return transactions;

    case TransactionFilter.income:
      return transactions
          .where((transaction) => transaction.type == TransactionType.income)
          .toList();

    case TransactionFilter.expense:
      return transactions
          .where((transaction) => transaction.type == TransactionType.expense)
          .toList();
  }
}
