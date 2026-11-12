import '../models/expense_category.dart';
import '../models/income_category.dart';
import '../models/payment_method.dart';

String categoryDisplayName(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.food:
      return 'Food';

    case ExpenseCategory.transport:
      return 'Transport';

    case ExpenseCategory.shopping:
      return 'Shopping';

    case ExpenseCategory.bills:
      return 'Bills';

    case ExpenseCategory.entertainment:
      return 'Entertainment';

    case ExpenseCategory.other:
      return 'Other';
  }
}

String paymentMethodDisplayName(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'Cash';

    case PaymentMethod.upi:
      return 'UPI';

    case PaymentMethod.creditCard:
      return 'Credit Card';

    case PaymentMethod.debitCard:
      return 'Debit Card';
  }
}

String incomeCategoryDisplayName(IncomeCategory category) {
  switch (category) {
    case IncomeCategory.salary:
      return 'Salary';

    case IncomeCategory.freelance:
      return 'Freelance';

    case IncomeCategory.business:
      return 'Business';

    case IncomeCategory.investment:
      return 'Investment';

    case IncomeCategory.other:
      return 'Other';
  }
}
