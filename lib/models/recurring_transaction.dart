import 'expense_category.dart';
import 'income_category.dart';
import 'payment_method.dart';
import 'transaction_type.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class RecurringTransaction {
  final String id;
  final String name;
  final double amount;
  final TransactionType type;
  final ExpenseCategory? expenseCategory;
  final IncomeCategory? incomeCategory;
  final PaymentMethod paymentMethod;
  final DateTime startDate;
  final DateTime nextDueDate;
  final RecurrenceFrequency frequency;
  final bool isActive;

  const RecurringTransaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    this.expenseCategory,
    this.incomeCategory,
    required this.paymentMethod,
    required this.startDate,
    DateTime? nextDueDate,
    required this.frequency,
    this.isActive = true,
  }) : nextDueDate = nextDueDate ?? startDate;

  RecurringTransaction copyWith({
    String? name,
    double? amount,
    TransactionType? type,
    ExpenseCategory? expenseCategory,
    IncomeCategory? incomeCategory,
    PaymentMethod? paymentMethod,
    DateTime? startDate,
    DateTime? nextDueDate,
    RecurrenceFrequency? frequency,
    bool? isActive,
    bool clearExpenseCategory = false,
    bool clearIncomeCategory = false,
  }) {
    return RecurringTransaction(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      expenseCategory: clearExpenseCategory
          ? null
          : expenseCategory ?? this.expenseCategory,
      incomeCategory: clearIncomeCategory
          ? null
          : incomeCategory ?? this.incomeCategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'type': type.name,
    'expenseCategory': expenseCategory?.name,
    'incomeCategory': incomeCategory?.name,
    'paymentMethod': paymentMethod.name,
    'startDate': startDate.toIso8601String(),
    'nextDueDate': nextDueDate.toIso8601String(),
    'frequency': frequency.name,
    'isActive': isActive,
  };

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    final startDate = DateTime.parse(map['startDate'] as String);
    return RecurringTransaction(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.byName(map['type'] as String),
      expenseCategory: map['expenseCategory'] == null
          ? null
          : ExpenseCategory.values.byName(map['expenseCategory'] as String),
      incomeCategory: map['incomeCategory'] == null
          ? null
          : IncomeCategory.values.byName(map['incomeCategory'] as String),
      paymentMethod: PaymentMethod.values.byName(
        map['paymentMethod'] as String,
      ),
      startDate: startDate,
      nextDueDate: map['nextDueDate'] == null
          ? startDate
          : DateTime.parse(map['nextDueDate'] as String),
      frequency: RecurrenceFrequency.values.byName(map['frequency'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
