import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../providers/transaction_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/transaction_helpers.dart';
import 'add_transaction_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionDetailsScreen extends ConsumerWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  Future<void> editTransaction(BuildContext context, WidgetRef ref) async {
    final updatedTransaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );

    if (updatedTransaction != null && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction?'),
          content: const Text('This transaction will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref
          .read(transactionProvider.notifier)
          .deleteTransaction(transaction.id);

      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                transaction.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                '${isIncome ? '+' : '-'}'
                '₹${transaction.amount.toStringAsFixed(2)}',

                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: isIncome ? Colors.green : Colors.red),
              ),
            ),

            const SizedBox(height: 8),

            Center(child: Text(isIncome ? 'Income' : 'Expense')),

            const SizedBox(height: 30),

            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Category'),
              trailing: Text(
                isIncome
                    ? incomeCategoryDisplayName(transaction.incomeCategory!)
                    : categoryDisplayName(transaction.expenseCategory!),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payment Method'),
              trailing: Text(
                paymentMethodDisplayName(transaction.paymentMethod),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              trailing: Text(formatDate(transaction.date)),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () => editTransaction(context, ref),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Transaction'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () => confirmDelete(context, ref),
                icon: const Icon(Icons.delete),
                label: const Text('Delete Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
