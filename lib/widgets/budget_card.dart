import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../utils/budget_calculator.dart';
import '../utils/transaction_helpers.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final double amountSpent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.amountSpent,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatAmount(double amount) => '₹${amount.toStringAsFixed(2)}';

  String _monthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return month >= 1 && month <= 12 ? monthNames[month - 1] : 'Month $month';
  }

  @override
  Widget build(BuildContext context) {
    final limit = budget.monthlyLimit;
    final remaining = calculateRemainingBudget(
      budgetLimit: limit,
      amountSpent: amountSpent,
    );
    final percentage = calculateBudgetPercentage(
      budgetLimit: limit,
      amountSpent: amountSpent,
    );
    final status = getBudgetStatus(
      amountSpent: amountSpent,
      budgetLimit: limit,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = switch (status) {
      'Budget exceeded' => colorScheme.error,
      'Approaching budget limit' => Colors.orange.shade800,
      'Invalid budget limit' => colorScheme.error,
      _ => colorScheme.primary,
    };

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      categoryDisplayName(budget.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit budget',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete budget',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              Text(
                '${_monthName(budget.month)} ${budget.year}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _formatAmount(amountSpent),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    'of ${_formatAmount(limit)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: limit > 0 ? (amountSpent / limit).clamp(0.0, 1.0) : 0,
                  minHeight: 10,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: statusColor,
                  semanticsLabel:
                      '${categoryDisplayName(budget.category)} budget',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    remaining < 0
                        ? Icons.warning_amber_rounded
                        : Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      remaining >= 0
                          ? '${_formatAmount(remaining)} remaining'
                          : '${_formatAmount(-remaining)} over budget',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: remaining < 0 ? colorScheme.error : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${percentage.toStringAsFixed(0)}% used',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: statusColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
