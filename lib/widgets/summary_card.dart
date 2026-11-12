import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color iconColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                '₹${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
