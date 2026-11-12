import 'expense_category.dart';
import 'income_category.dart';
import 'payment_method.dart';
import 'transaction_type.dart';

class Transaction {
  final String id;
  final String name;
  final double amount;
  final TransactionType type;

  final ExpenseCategory? expenseCategory;
  final IncomeCategory? incomeCategory;

  final DateTime date;
  final PaymentMethod paymentMethod;

  Transaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    this.expenseCategory,
    this.incomeCategory,
    required this.date,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type.name,
      'expenseCategory': expenseCategory?.name,
      'incomeCategory': incomeCategory?.name,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod.name,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      type: TransactionType.values.byName(map['type']),
      expenseCategory: map['expenseCategory'] != null
          ? ExpenseCategory.values.byName(map['expenseCategory'])
          : null,
      incomeCategory: map['incomeCategory'] != null
          ? IncomeCategory.values.byName(map['incomeCategory'])
          : null,
      date: DateTime.parse(map['date']),
      paymentMethod: PaymentMethod.values.byName(map['paymentMethod']),
    );
  }
}
