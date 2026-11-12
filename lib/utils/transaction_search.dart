import '../models/transaction.dart';

List<Transaction> searchTransactions(
  List<Transaction> transactions,
  String query,
) {
  if (query.trim().isEmpty) {
    return transactions;
  }

  final searchQuery = query.trim().toLowerCase();

  return transactions.where((transaction) {
    return transaction.name.toLowerCase().contains(searchQuery);
  }).toList();
}
