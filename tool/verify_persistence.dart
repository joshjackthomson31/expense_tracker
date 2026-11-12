// Verifies Lesson 48: transactions survive a simulated app restart.
//
// Run with: dart run tool/verify_persistence.dart
//
// This exercises the real TransactionRepository + Hive code. "Restarting the
// app" is simulated by closing the Hive box and creating a fresh repository,
// exactly like a new app process opening the same box on disk would.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/income_category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/repositories/hive_transaction_repository.dart';
import 'package:hive/hive.dart';

int failures = 0;

void check(String description, bool condition) {
  if (condition) {
    print('  PASS: $description');
  } else {
    failures++;
    print('  FAIL: $description');
  }
}

Future<void> simulateAppRestart() async {
  await Hive.box(HiveTransactionRepository.boxName).close();
}

Future<void> main() async {
  final tempDir = await Directory.systemTemp.createTemp('hive_persistence_check');
  Hive.init(tempDir.path);

  try {
    print('Test 1: added transaction survives a restart');
    {
      final repository = HiveTransactionRepository();

      final lunch = Transaction(
        id: '1',
        name: 'Lunch',
        amount: 350,
        type: TransactionType.expense,
        expenseCategory: ExpenseCategory.food,
        date: DateTime(2026, 10, 8),
        paymentMethod: PaymentMethod.upi,
      );

      await repository.saveTransaction(lunch);
      await simulateAppRestart();

      final loaded = await HiveTransactionRepository().getTransactions();

      check('exactly one transaction loaded', loaded.length == 1);
      check('name is Lunch', loaded.first.name == 'Lunch');
      check('amount is 350', loaded.first.amount == 350);
      check(
        'category is food',
        loaded.first.expenseCategory == ExpenseCategory.food,
      );
    }

    print('Test 2: updated transaction survives a restart');
    {
      final repository = HiveTransactionRepository();

      final updatedLunch = Transaction(
        id: '1',
        name: 'Lunch',
        amount: 500,
        type: TransactionType.expense,
        expenseCategory: ExpenseCategory.food,
        date: DateTime(2026, 10, 8),
        paymentMethod: PaymentMethod.upi,
      );

      await repository.updateTransaction(updatedLunch);
      await simulateAppRestart();

      final loaded = await HiveTransactionRepository().getTransactions();

      check('exactly one transaction loaded', loaded.length == 1);
      check('amount updated to 500', loaded.first.amount == 500);
    }

    print('Test 3: deleted transaction stays deleted after a restart');
    {
      final repository = HiveTransactionRepository();

      final salary = Transaction(
        id: '2',
        name: 'Salary',
        amount: 50000,
        type: TransactionType.income,
        incomeCategory: IncomeCategory.salary,
        date: DateTime(2026, 10, 1),
        paymentMethod: PaymentMethod.upi,
      );

      await repository.saveTransaction(salary);
      await repository.deleteTransaction('1');
      await simulateAppRestart();

      final loaded = await HiveTransactionRepository().getTransactions();

      check('only the salary transaction remains', loaded.length == 1);
      check('remaining transaction is Salary', loaded.first.id == '2');
    }
  } finally {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  }

  print('');

  if (failures == 0) {
    print('All persistence checks passed.');
    exit(0);
  } else {
    print('$failures check(s) failed.');
    exit(1);
  }
}
