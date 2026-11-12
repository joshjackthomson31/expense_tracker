import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/recurring_transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recurring transaction survives map serialization', () {
    final original = RecurringTransaction(
      id: 'rent-1',
      name: 'Rent',
      amount: 1800.50,
      type: TransactionType.expense,
      expenseCategory: ExpenseCategory.bills,
      paymentMethod: PaymentMethod.upi,
      startDate: DateTime(2026, 1, 31),
      nextDueDate: DateTime(2026, 2, 28),
      frequency: RecurrenceFrequency.monthly,
      isActive: false,
    );

    final restored = RecurringTransaction.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.amount, original.amount);
    expect(restored.type, original.type);
    expect(restored.expenseCategory, original.expenseCategory);
    expect(restored.paymentMethod, original.paymentMethod);
    expect(restored.startDate, original.startDate);
    expect(restored.nextDueDate, original.nextDueDate);
    expect(restored.frequency, original.frequency);
    expect(restored.isActive, original.isActive);
  });
}
