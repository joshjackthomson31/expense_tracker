import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double balance;

  const BalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total balance',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                '₹${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Income minus expenses',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
