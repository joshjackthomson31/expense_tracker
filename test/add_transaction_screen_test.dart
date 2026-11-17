import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/income_category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/utils/date_filter.dart';
import 'package:expense_tracker/utils/spending_chart_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openForm(
    WidgetTester tester,
    _Transactions notifier, {
    Transaction? transaction,
  }) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [transactionProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<Transaction>(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddTransactionScreen(transaction: transaction),
                  ),
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  for (final type in TransactionType.values) {
    for (final editing in [false, true]) {
      testWidgets('$type ${editing ? 'edit' : 'add'} works at 320px', (
        tester,
      ) async {
        final expense = type == TransactionType.expense;
        final existing = Transaction(
          id: 'existing',
          name: 'Existing transaction',
          amount: 150,
          type: type,
          expenseCategory: expense ? ExpenseCategory.entertainment : null,
          incomeCategory: expense ? null : IncomeCategory.investment,
          date: DateTime(2026, 1, 30),
          paymentMethod: PaymentMethod.creditCard,
        );
        final notifier = _Transactions();
        await openForm(
          tester,
          notifier,
          transaction: editing ? existing : null,
        );
        expect(tester.takeException(), isNull);
        if (editing) {
          expect(find.text('Existing transaction'), findsOneWidget);
          expect(find.text('150.0'), findsOneWidget);
          expect(find.text('30 Jan 2026'), findsOneWidget);
        } else if (!expense) {
          await tester.tap(find.text('Income'));
          await tester.pumpAndSettle();
        }

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Regression transaction');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.enterText(fields.at(1), '250');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();

        final category = expense
            ? find.byType(DropdownButtonFormField<ExpenseCategory>)
            : find.byType(DropdownButtonFormField<IncomeCategory>);
        await reveal(tester, category);
        await tester.tap(category);
        await tester.pumpAndSettle();
        final label = expense ? 'Entertainment' : 'Investment';
        await reveal(tester, find.text(label).last);
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();

        final payment = find.byType(DropdownButtonFormField<PaymentMethod>);
        await reveal(tester, payment);
        await tester.tap(payment);
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Credit Card').last);
        await tester.tap(find.text('Credit Card').last);
        await tester.pumpAndSettle();

        final save = find.byType(ElevatedButton);
        await reveal(tester, save);
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.text('Open form'), findsOneWidget);
        final saved = notifier.saved!;
        expect(saved.name, 'Regression transaction');
        expect(saved.amount, 250);
        expect(saved.type, type);
        expect(saved.paymentMethod, PaymentMethod.creditCard);
        expect(
          saved.expenseCategory,
          expense ? ExpenseCategory.entertainment : null,
        );
        expect(
          saved.incomeCategory,
          expense ? null : IncomeCategory.investment,
        );
        expect(notifier.updated, editing);
        if (editing) {
          expect(saved.id, existing.id);
          expect(saved.date, existing.date);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('validation still rejects invalid names and amounts at 320px', (
    tester,
  ) async {
    final notifier = _Transactions();
    await openForm(tester, notifier);
    final fields = find.byType(TextFormField);
    final save = find.byType(ElevatedButton);
    const invalidAmounts = {
      '': 'Enter an amount',
      '0': 'Amount must be greater than 0',
      '-1': 'Amount must be greater than 0',
      'invalid': 'Enter a valid amount',
      'NaN': 'Enter a valid amount',
    };
    for (final entry in invalidAmounts.entries) {
      await reveal(tester, fields.at(1));
      await tester.enterText(fields.at(1), entry.key);
      tester.testTextInput.hide();
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final form = tester.state<FormState>(find.byType(Form));
      expect(form.validate(), isFalse);
      expect(notifier.saved, isNull);
      expect(find.text('Enter a title'), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('late-entered expense saves and charts the selected past date', (
    tester,
  ) async {
    final notifier = _Transactions();
    await openForm(tester, notifier);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Late expense');
    await tester.enterText(fields.at(1), '125');
    tester.testTextInput.hide();
    await reveal(tester, find.byType(DropdownButtonFormField<ExpenseCategory>));
    await tester.tap(find.byType(DropdownButtonFormField<ExpenseCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();
    await reveal(tester, find.byIcon(Icons.calendar_today));
    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final past = DateTime(now.year, now.month, now.day - 9);
    final context = tester.element(find.byType(DatePickerDialog));
    final dateField = find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(
      dateField,
      MaterialLocalizations.of(context).formatCompactDate(past),
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    final saved = notifier.saved!;
    expect(saved.date, past);
    expect(calculateWeeklySpending([saved], past), {past: 125.0});
    expect(startOfWeek(past), isNot(startOfWeek(now)));
    expect(calculateWeeklySpending([saved], now), isEmpty);
    expect(tester.takeException(), isNull);
  });
}

class _Transactions extends TransactionNotifier {
  Transaction? saved;
  bool updated = false;

  @override
  Future<List<Transaction>> build() async => [];

  @override
  Future<void> addTransaction(Transaction transaction) async {
    saved = transaction;
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    saved = transaction;
    updated = true;
  }
}
