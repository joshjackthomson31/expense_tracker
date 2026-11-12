import 'package:flutter/material.dart';

import 'recurring_transactions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _heading(context, 'Appearance'),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Icon(
                  Icons.currency_rupee,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Currency'),
                subtitle: const Text('Indian Rupee (INR · ₹)'),
              ),
            ),
            const SizedBox(height: 24),
            _heading(context, 'Data'),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Icon(
                  Icons.event_repeat,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Recurring Transactions'),
                subtitle: const Text('Manage repeating expenses and income'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RecurringTransactionsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Icon(
                  Icons.storage_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Data & Storage'),
                subtitle: const Text(
                  'Transactions, budgets, and recurring schedules are stored '
                  'locally on this device.',
                ),
              ),
            ),
            const SizedBox(height: 24),
            _heading(context, 'About'),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: const Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(Icons.info_outline),
                    title: Text('About Expense Tracker'),
                    subtitle: Text(
                      'Track expenses, income, budgets, and analytics.',
                    ),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(Icons.tag),
                    title: Text('Version'),
                    subtitle: Text('1.0.0 (build 1)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expense Tracker',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your money simply.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
