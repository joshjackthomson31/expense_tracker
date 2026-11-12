import 'expense_category.dart';

class Budget {
  final String id;
  final ExpenseCategory category;
  final double monthlyLimit;
  final int year;
  final int month;

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.year,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'monthlyLimit': monthlyLimit,
      'year': year,
      'month': month,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      category: ExpenseCategory.values.byName(map['category'] as String),
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      year: map['year'] as int,
      month: map['month'] as int,
    );
  }
}
