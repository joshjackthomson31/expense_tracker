import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_filter.dart';
import '../models/transaction_sort.dart';
import '../providers/transaction_provider.dart';
import '../utils/transaction_filter.dart';
import '../utils/transaction_search.dart';
import '../utils/transaction_sort.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_details_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionFilter selectedFilter = TransactionFilter.all;
  TransactionSort selectedSort = TransactionSort.newest;

  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (transactions) {
        final filteredTransactions = filterTransactions(
          transactions,
          selectedFilter,
        );

        final searchedTransactions = searchTransactions(
          filteredTransactions,
          searchController.text,
        );

        final displayedTransactions = [...searchedTransactions];
        sortTransactions(displayedTransactions, selectedSort);

        return Scaffold(
          appBar: AppBar(title: const Text('Transactions')),

          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),

                child: TextField(
                  controller: searchController,

                  onChanged: (_) {
                    setState(() {});
                  },

                  decoration: const InputDecoration(
                    hintText: 'Search transactions',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: SegmentedButton<TransactionFilter>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionFilter.all,
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: TransactionFilter.income,
                      label: Text('Income'),
                    ),
                    ButtonSegment(
                      value: TransactionFilter.expense,
                      label: Text('Expense'),
                    ),
                  ],

                  selected: {selectedFilter},

                  onSelectionChanged: (selection) {
                    setState(() {
                      selectedFilter = selection.first;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Row(
                  children: [
                    const Text('Sort by: '),

                    DropdownButton<TransactionSort>(
                      value: selectedSort,

                      items: const [
                        DropdownMenuItem(
                          value: TransactionSort.newest,
                          child: Text('Newest'),
                        ),
                        DropdownMenuItem(
                          value: TransactionSort.oldest,
                          child: Text('Oldest'),
                        ),
                        DropdownMenuItem(
                          value: TransactionSort.amountHighToLow,
                          child: Text('Amount: High to Low'),
                        ),
                        DropdownMenuItem(
                          value: TransactionSort.amountLowToHigh,
                          child: Text('Amount: Low to High'),
                        ),
                      ],

                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedSort = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('No transactions yet.'))
                    : displayedTransactions.isEmpty
                    ? const Center(
                        child: Text('No transactions match your search.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),

                        itemCount: displayedTransactions.length,

                        itemBuilder: (context, index) {
                          final transaction = displayedTransactions[index];

                          return TransactionTile(
                            transaction: transaction,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TransactionDetailsScreen(
                                        transaction: transaction,
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
