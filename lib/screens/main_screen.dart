import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'transactions_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'budgets_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    BudgetsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
