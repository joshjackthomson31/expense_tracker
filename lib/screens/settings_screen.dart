import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import 'recurring_transactions_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.brightness_6_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Theme',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(selection.first),
                      ),
                    ),
                  ],
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
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showInformation(
                  context,
                  'Data & Storage',
                  kIsWeb
                      ? 'Your transactions, budgets, recurring schedules, and '
                            'theme preference are stored in this browser on this '
                            'device. There is no cloud sync or automatic backup. '
                            'Clearing website data or browser storage can remove '
                            'your records. Data is not shared with the Android app '
                            'or other devices.'
                      : 'Your transactions, budgets, recurring schedules, and '
                            'theme preference are stored locally on this device. '
                            'There is no cloud sync or automatic backup. Clearing '
                            'app storage or uninstalling the app can remove your '
                            'records. Data is not shared with other devices.',
                ),
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
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Expense Tracker'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showInformation(
                      context,
                      'About Expense Tracker',
                      'Track income, expenses, budgets, and recurring schedules '
                          'in Indian Rupees. Home shows the current month; Analytics '
                          'lets you explore individual months and all-time totals. '
                          'Recurring reminders appear in the app starting two days '
                          'before the due date; they are not phone notifications.',
                    ),
                    subtitle: const Text(
                      'Track expenses, income, budgets, and analytics.',
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.tag),
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0 (build 1)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showInformation(
                      context,
                      'Version',
                      'Expense Tracker\nVersion 1.0.0 (build 1)',
                    ),
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

  void _showInformation(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        scrollable: true,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
