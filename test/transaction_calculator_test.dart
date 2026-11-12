import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/utils/transaction_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction makeTransaction({
  required String id,
  required double amount,
  required TransactionType type,
}) {
  return Transaction(
    id: id,
    name: id,
    amount: amount,
    type: type,
    date: DateTime(2026, 10, 1),
    paymentMethod: PaymentMethod.cash,
  );
}

void main() {
  group('Transaction calculations', () {
    test('totals expenses and excludes income', () {
      final transactions = [
        makeTransaction(
          id: 'lunch',
          amount: 350,
          type: TransactionType.expense,
        ),
        makeTransaction(
          id: 'rent',
          amount: 15000,
          type: TransactionType.expense,
        ),
        makeTransaction(
          id: 'salary',
          amount: 50000,
          type: TransactionType.income,
        ),
      ];

      expect(calculateTotalExpense(transactions), 15350.0);
    });

    test('totals income and excludes expenses', () {
      final transactions = [
        makeTransaction(
          id: 'salary',
          amount: 50000,
          type: TransactionType.income,
        ),
        makeTransaction(
          id: 'freelance',
          amount: 2500,
          type: TransactionType.income,
        ),
        makeTransaction(
          id: 'lunch',
          amount: 350,
          type: TransactionType.expense,
        ),
      ];

      expect(calculateTotalIncome(transactions), 52500.0);
    });

    test('calculates balance as income minus expenses', () {
      final transactions = [
        makeTransaction(
          id: 'salary',
          amount: 50000,
          type: TransactionType.income,
        ),
        makeTransaction(
          id: 'rent',
          amount: 15000,
          type: TransactionType.expense,
        ),
      ];

      expect(calculateBalance(transactions), 35000.0);
    });

    test('returns zero totals when there are no transactions', () {
      expect(calculateTotalIncome([]), 0.0);
      expect(calculateTotalExpense([]), 0.0);
      expect(calculateBalance([]), 0.0);
    });
  });
}
