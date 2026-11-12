import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../models/income_category.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../utils/date_formatter.dart';
import '../utils/transaction_helpers.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  IconData getCategoryIcon() {
    switch (transaction.expenseCategory!) {
      case ExpenseCategory.food:
        return Icons.restaurant;

      case ExpenseCategory.transport:
        return Icons.directions_bus;

      case ExpenseCategory.shopping:
        return Icons.shopping_bag;

      case ExpenseCategory.bills:
        return Icons.receipt_long;

      case ExpenseCategory.entertainment:
        return Icons.movie;

      case ExpenseCategory.other:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amountColor = isIncome ? Colors.green.shade700 : colorScheme.error;
    final categoryName = isIncome
        ? incomeCategoryDisplayName(
            transaction.incomeCategory ?? IncomeCategory.other,
          )
        : categoryDisplayName(
            transaction.expenseCategory ?? ExpenseCategory.other,
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    isIncome ? Icons.savings_outlined : getCategoryIcon(),
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$categoryName • '
                      '${paymentMethodDisplayName(transaction.paymentMethod)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDate(transaction.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 112,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${isIncome ? '+' : '-'}'
                    '₹${transaction.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
