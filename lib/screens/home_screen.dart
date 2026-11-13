import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/transaction_calculator.dart';
import '../widgets/balance_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/upcoming_recurring_card.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> addTransaction(BuildContext context, WidgetRef ref) async {
    final transaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );

    if (transaction != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully')),
      );
    }
  }

  Future<void> editTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final updatedTransaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );

    if (updatedTransaction != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated successfully')),
      );
    }
  }

  void openTransactions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionsScreen()),
    );
  }

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';

    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (transactions) {
        final balance = calculateBalance(transactions);
        final totalIncome = calculateTotalIncome(transactions);
        final totalExpenses = calculateTotalExpense(transactions);

        final recentTransactions = ([
          ...transactions,
        ]..sort((a, b) => b.date.compareTo(a.date))).take(5).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Expense Tracker',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            titleSpacing: 20,
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(
                  greeting(),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's your spending summary",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                const UpcomingRecurringCard(),
                BalanceCard(balance: balance),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final incomeCard = SummaryCard(
                      title: 'Income',
                      amount: totalIncome,
                      icon: Icons.arrow_downward_rounded,
                      iconColor: Colors.green,
                    );
                    final expensesCard = SummaryCard(
                      title: 'Expenses',
                      amount: totalExpenses,
                      icon: Icons.arrow_upward_rounded,
                      iconColor: Colors.red,
                    );

                    if (constraints.maxWidth < 350) {
                      return Column(
                        children: [
                          incomeCard,
                          const SizedBox(height: 12),
                          expensesCard,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: incomeCard),
                        const SizedBox(width: 12),
                        Expanded(child: expensesCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Recent transactions',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (transactions.isNotEmpty)
                      TextButton(
                        onPressed: () => openTransactions(context),
                        child: const Text('See all'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  _EmptyTransactions(
                    onAddTransaction: () => addTransaction(context, ref),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = recentTransactions[index];

                      return Dismissible(
                        key: Key(transaction.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                        onDismissed: (direction) {
                          ref
                              .read(transactionProvider.notifier)
                              .deleteTransaction(transaction.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Transaction deleted'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () {
                                  ref
                                      .read(transactionProvider.notifier)
                                      .addTransaction(transaction);
                                },
                              ),
                            ),
                          );
                        },
                        child: TransactionTile(
                          transaction: transaction,
                          onTap: () =>
                              editTransaction(context, ref, transaction),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              heightFactor: 1,
              child: FloatingActionButton.extended(
                onPressed: () => addTransaction(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add transaction'),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  final VoidCallback onAddTransaction;

  const _EmptyTransactions({required this.onAddTransaction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first transaction to start tracking your finances.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAddTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Add transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
