import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_category.dart';
import '../models/income_category.dart';
import '../models/payment_method.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../providers/transaction_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/transaction_helpers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final amountController = TextEditingController();

  TransactionType selectedType = TransactionType.expense;
  ExpenseCategory? selectedExpenseCategory;
  IncomeCategory? selectedIncomeCategory;
  PaymentMethod selectedPaymentMethod = PaymentMethod.upi;

  DateTime selectedDate = DateTime.now();

  bool isSubmitting = false;

  bool get isExpense => selectedType == TransactionType.expense;

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    if (transaction != null) {
      nameController.text = transaction.name;
      amountController.text = transaction.amount.toString();

      selectedType = transaction.type;
      selectedPaymentMethod = transaction.paymentMethod;
      selectedDate = transaction.date;

      if (transaction.expenseCategory != null) {
        selectedExpenseCategory = transaction.expenseCategory!;
      }

      if (transaction.incomeCategory != null) {
        selectedIncomeCategory = transaction.incomeCategory!;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();

    super.dispose();
  }

  Future<void> selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  bool validateCategory() {
    if (isExpense) {
      return selectedExpenseCategory != null;
    }

    return selectedIncomeCategory != null;
  }

  Future<void> saveTransaction() async {
    if (isSubmitting) {
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!validateCategory()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));

      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final transaction = Transaction(
      id:
          widget.transaction?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      amount: double.parse(amountController.text),
      type: selectedType,
      expenseCategory: isExpense ? selectedExpenseCategory : null,
      incomeCategory: isExpense ? null : selectedIncomeCategory,
      date: selectedDate,
      paymentMethod: selectedPaymentMethod,
    );

    try {
      if (isEditing) {
        await ref
            .read(transactionProvider.notifier)
            .updateTransaction(transaction);
      } else {
        await ref
            .read(transactionProvider.notifier)
            .addTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context, transaction);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save transaction')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit Transaction'
              : (isExpense ? 'Add Expense' : 'Add Income'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],

                selected: {selectedType},

                onSelectionChanged: (selection) {
                  setState(() {
                    selectedType = selection.first;
                    selectedExpenseCategory = null;
                    selectedIncomeCategory = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: isExpense ? 'Expense Name' : 'Income Name',
                  hintText: isExpense ? 'Example: Lunch' : 'Example: Salary',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a title';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Example: 500',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an amount';
                  }

                  final amount = double.tryParse(value.trim());

                  if (amount == null || !amount.isFinite) {
                    return 'Enter a valid amount';
                  }

                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (isExpense)
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: selectedExpenseCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Expense Category',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select a category'),
                  items: ExpenseCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(categoryDisplayName(category)),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedExpenseCategory = value;
                    });
                  },
                )
              else
                DropdownButtonFormField<IncomeCategory>(
                  initialValue: selectedIncomeCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Income Category',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select a category'),
                  items: IncomeCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(incomeCategoryDisplayName(category)),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedIncomeCategory = value;
                    });
                  },
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: selectedPaymentMethod,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: PaymentMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(paymentMethodDisplayName(method)),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedPaymentMethod = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(formatDate(selectedDate)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: selectDate,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : saveTransaction,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isEditing ? 'Update Transaction' : 'Save Transaction',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
