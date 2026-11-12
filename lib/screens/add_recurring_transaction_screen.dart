import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_category.dart';
import '../models/income_category.dart';
import '../models/payment_method.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction_type.dart';
import '../providers/recurring_transaction_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/recurrence_helper.dart';
import '../utils/transaction_helpers.dart';

class AddRecurringTransactionScreen extends ConsumerStatefulWidget {
  final RecurringTransaction? existingTransaction;

  const AddRecurringTransactionScreen({super.key, this.existingTransaction});

  bool get isEditing => existingTransaction != null;

  @override
  ConsumerState<AddRecurringTransactionScreen> createState() =>
      _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState
    extends ConsumerState<AddRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  ExpenseCategory _expenseCategory = ExpenseCategory.food;
  IncomeCategory _incomeCategory = IncomeCategory.salary;
  PaymentMethod _paymentMethod = PaymentMethod.upi;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  DateTime _startDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingTransaction;
    if (existing == null) return;

    _nameController.text = existing.name;
    _amountController.text = existing.amount.toStringAsFixed(2);
    _type = existing.type;
    _expenseCategory = existing.expenseCategory ?? _expenseCategory;
    _incomeCategory = existing.incomeCategory ?? _incomeCategory;
    _paymentMethod = existing.paymentMethod;
    _frequency = existing.frequency;
    _startDate = existing.startDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit Recurring Transaction'
              : 'Add Recurring Transaction',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Example: House Rent',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Example: 15000',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || !amount.isFinite) {
                    return 'Enter a valid amount';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Transaction Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _isSaving
                    ? null
                    : (selection) => setState(() => _type = selection.first),
              ),
              const SizedBox(height: 20),
              if (_type == TransactionType.expense)
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: _expenseCategory,
                  decoration: const InputDecoration(
                    labelText: 'Expense Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ExpenseCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(categoryDisplayName(category)),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (category) {
                          if (category != null) {
                            setState(() => _expenseCategory = category);
                          }
                        },
                )
              else
                DropdownButtonFormField<IncomeCategory>(
                  initialValue: _incomeCategory,
                  decoration: const InputDecoration(
                    labelText: 'Income Category',
                    border: OutlineInputBorder(),
                  ),
                  items: IncomeCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(incomeCategoryDisplayName(category)),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (category) {
                          if (category != null) {
                            setState(() => _incomeCategory = category);
                          }
                        },
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: PaymentMethod.values
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(paymentMethodDisplayName(method)),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (method) {
                        if (method != null) {
                          setState(() => _paymentMethod = method);
                        }
                      },
              ),
              const SizedBox(height: 20),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Recurring Transaction',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<RecurrenceFrequency>(
                        initialValue: _frequency,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(),
                        ),
                        items: RecurrenceFrequency.values
                            .map(
                              (frequency) => DropdownMenuItem(
                                value: frequency,
                                child: Text(_frequencyLabel(frequency)),
                              ),
                            )
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (frequency) {
                                if (frequency != null) {
                                  setState(() => _frequency = frequency);
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: Text(
                            widget.isEditing
                                ? 'Schedule Anchor Date'
                                : 'Start Date',
                          ),
                          subtitle: Text(_formatDate(_startDate)),
                          trailing: widget.isEditing
                              ? null
                              : const Icon(Icons.chevron_right),
                          onTap: _isSaving || widget.isEditing
                              ? null
                              : _selectStartDate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This creates a schedule only. A transaction is added to your '
                        'totals when you record a due payment.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Next due: ${formatDate(widget.existingTransaction?.nextDueDate ?? _startDate)}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Following occurrence: ${formatDate(calculateNextDueDate(currentDueDate: widget.existingTransaction?.nextDueDate ?? _startDate, frequency: _frequency, preferredDay: _startDate.day))}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : widget.isEditing
                      ? 'Update Recurring Transaction'
                      : 'Save Recurring Transaction',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;
    setState(() => _startDate = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final existing = widget.existingTransaction;
      final recurring = RecurringTransaction(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _type,
        expenseCategory: _type == TransactionType.expense
            ? _expenseCategory
            : null,
        incomeCategory: _type == TransactionType.income
            ? _incomeCategory
            : null,
        paymentMethod: _paymentMethod,
        startDate: existing?.startDate ?? _startDate,
        nextDueDate: existing?.nextDueDate ?? _startDate,
        frequency: _frequency,
        isActive: existing?.isActive ?? true,
      );

      final notifier = ref.read(recurringTransactionProvider.notifier);
      if (widget.isEditing) {
        await notifier.updateRecurringTransaction(recurring);
      } else {
        await notifier.addRecurringTransaction(recurring);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save recurring transaction: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _frequencyLabel(RecurrenceFrequency frequency) => switch (frequency) {
    RecurrenceFrequency.daily => 'Daily',
    RecurrenceFrequency.weekly => 'Weekly',
    RecurrenceFrequency.monthly => 'Monthly',
    RecurrenceFrequency.yearly => 'Yearly',
  };

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
