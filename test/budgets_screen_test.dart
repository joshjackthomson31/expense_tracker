import 'package:expense_tracker/models/budget.dart';
import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/providers/budget_provider.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/repositories/budget_repository.dart';
import 'package:expense_tracker/repositories/transaction_repository.dart';
import 'package:expense_tracker/screens/budgets_screen.dart';
import 'package:expense_tracker/widgets/budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('budget tracks added, updated, and deleted expenses', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        budgetRepositoryProvider.overrideWithValue(_BudgetRepository()),
        transactionRepositoryProvider.overrideWithValue(
          _TransactionRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BudgetsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No budgets for this month'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add budget'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '4000');
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();

    final date = DateTime.now();
    Transaction expense(double amount) => Transaction(
      id: 'groceries',
      name: 'Groceries',
      amount: amount,
      type: TransactionType.expense,
      expenseCategory: ExpenseCategory.food,
      date: date,
      paymentMethod: PaymentMethod.upi,
    );

    final notifier = container.read(transactionProvider.notifier);
    await notifier.addTransaction(expense(3000));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(BudgetCard), 200);
    final card = find.byType(BudgetCard);
    expect(
      find.descendant(of: card, matching: find.text('₹1000.00 remaining')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.descendant(
              of: card,
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .value,
      0.75,
    );

    await notifier.updateTransaction(expense(5000));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('₹1000.00 over budget')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.descendant(
              of: card,
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .value,
      1,
    );

    await notifier.deleteTransaction('groceries');
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('₹0.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('₹4000.00 remaining')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byTooltip('Edit budget'));
    await tester.tap(find.byTooltip('Edit budget'));
    await tester.pumpAndSettle();
    expect(find.text('Edit budget'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '4000.0',
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Delete budget'));
    await tester.tap(find.byTooltip('Delete budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCard), findsNothing);
    expect(find.text('No budgets for this month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _BudgetRepository implements BudgetRepository {
  final List<Budget> _budgets = [];

  @override
  Future<List<Budget>> getBudgets() async => List.of(_budgets);

  @override
  Future<void> saveBudget(Budget budget) async => _budgets.add(budget);

  @override
  Future<void> updateBudget(Budget budget) async {
    final index = _budgets.indexWhere((item) => item.id == budget.id);
    _budgets[index] = budget;
  }

  @override
  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((item) => item.id == id);
  }
}

class _TransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];

  @override
  Future<List<Transaction>> getTransactions() async => List.of(_transactions);

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    _transactions[index] = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clearAllTransactions() async => _transactions.clear();
}
