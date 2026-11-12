import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../repositories/hive_recurring_transaction_repository.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../utils/recurrence_helper.dart';

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>((ref) {
      return HiveRecurringTransactionRepository();
    });

class RecurringTransactionNotifier
    extends AsyncNotifier<List<RecurringTransaction>> {
  final Set<String> _recordingIds = {};

  @override
  Future<List<RecurringTransaction>> build() {
    return ref
        .read(recurringTransactionRepositoryProvider)
        .getRecurringTransactions();
  }

  Future<void> addRecurringTransaction(RecurringTransaction recurring) async {
    final current = state.value ?? [];
    if (current.any((item) => item.id == recurring.id)) {
      throw StateError('This recurring transaction already exists.');
    }
    await ref
        .read(recurringTransactionRepositoryProvider)
        .saveRecurringTransaction(recurring);
    state = AsyncData([...current, recurring]);
  }

  Future<void> updateRecurringTransaction(
    RecurringTransaction recurring,
  ) async {
    final current = state.value ?? [];
    if (!current.any((item) => item.id == recurring.id)) {
      throw StateError('Recurring transaction not found.');
    }
    await ref
        .read(recurringTransactionRepositoryProvider)
        .updateRecurringTransaction(recurring);
    state = AsyncData([
      for (final item in current)
        if (item.id == recurring.id) recurring else item,
    ]);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await ref
        .read(recurringTransactionRepositoryProvider)
        .deleteRecurringTransaction(id);
    state = AsyncData(
      (state.value ?? []).where((item) => item.id != id).toList(),
    );
  }

  Future<void> recordDueOccurrence(RecurringTransaction recurring) async {
    if (!_recordingIds.add(recurring.id)) {
      throw StateError('This occurrence is already being recorded.');
    }

    try {
      // Always use the latest schedule from provider state. The screen may
      // pass an old schedule object after a previous tap has updated it.
      final currentSchedules = state.value;
      if (currentSchedules == null) {
        throw StateError('Recurring transactions are still loading.');
      }

      final currentIndex = currentSchedules.indexWhere(
        (item) => item.id == recurring.id,
      );

      if (currentIndex == -1) {
        throw StateError('Recurring transaction not found.');
      }

      final current = currentSchedules[currentIndex];

      if (!current.isActive) {
        throw StateError('This recurring transaction is paused.');
      }

      final today = DateTime.now();
      if (_dateOnly(current.nextDueDate).isAfter(_dateOnly(today))) {
        throw StateError('This recurring transaction is not due yet.');
      }

      // One stable ID per schedule and due date prevents duplicate entries.
      final occurrenceId = createOccurrenceKey(
        recurringId: current.id,
        dueDate: current.nextDueDate,
      );

      final transactionRepository = ref.read(transactionRepositoryProvider);
      final transactions = await transactionRepository.getTransactions();

      final alreadyRecorded = transactions.any(
        (transaction) => transaction.id == occurrenceId,
      );

      // If a previous attempt saved the transaction but failed to advance the
      // schedule, reuse the existing occurrence instead of adding it twice.
      if (!alreadyRecorded) {
        final transaction = Transaction(
          id: occurrenceId,
          name: current.name,
          amount: current.amount,
          type: current.type,
          expenseCategory: current.expenseCategory,
          incomeCategory: current.incomeCategory,
          date: current.nextDueDate,
          paymentMethod: current.paymentMethod,
        );

        await ref
            .read(transactionProvider.notifier)
            .addTransaction(transaction);
      }

      // Advance from the current due date, not from today's date. This
      // preserves the intended schedule even when a payment is overdue.
      final nextDueDate = calculateNextDueDate(
        currentDueDate: current.nextDueDate,
        frequency: current.frequency,
        preferredDay: current.startDate.day,
      );

      await updateRecurringTransaction(
        current.copyWith(nextDueDate: nextDueDate),
      );
    } finally {
      _recordingIds.remove(recurring.id);
    }
  }

  Future<int> catchUpOverdueOccurrences(
    RecurringTransaction recurring, {
    int maxOccurrences = 500,
  }) async {
    if (!_recordingIds.add(recurring.id)) {
      throw StateError('This schedule is already being processed.');
    }

    var processedCount = 0;

    try {
      final schedules = state.value;
      if (schedules == null) {
        throw StateError('Recurring transactions are still loading.');
      }

      final index = schedules.indexWhere((item) => item.id == recurring.id);

      if (index == -1) {
        throw StateError('Recurring transaction not found.');
      }

      var current = schedules[index];

      if (!current.isActive) {
        throw StateError('This recurring transaction is paused.');
      }

      final today = _dateOnly(DateTime.now());
      final transactionRepository = ref.read(transactionRepositoryProvider);

      while (!_dateOnly(current.nextDueDate).isAfter(today) &&
          processedCount < maxOccurrences) {
        final dueDate = current.nextDueDate;

        final occurrenceId = createOccurrenceKey(
          recurringId: current.id,
          dueDate: dueDate,
        );

        final transactions = await transactionRepository.getTransactions();

        final alreadyRecorded = transactions.any(
          (transaction) => transaction.id == occurrenceId,
        );

        if (!alreadyRecorded) {
          final transaction = Transaction(
            id: occurrenceId,
            name: current.name,
            amount: current.amount,
            type: current.type,
            expenseCategory: current.expenseCategory,
            incomeCategory: current.incomeCategory,
            date: dueDate,
            paymentMethod: current.paymentMethod,
          );

          await ref
              .read(transactionProvider.notifier)
              .addTransaction(transaction);
        }

        final nextDueDate = calculateNextDueDate(
          currentDueDate: dueDate,
          frequency: current.frequency,
          preferredDay: current.startDate.day,
        );

        current = current.copyWith(nextDueDate: nextDueDate);

        // Save each advancement immediately so retries resume without
        // duplicating occurrences already recorded.
        await updateRecurringTransaction(current);

        processedCount++;
      }

      return processedCount;
    } finally {
      _recordingIds.remove(recurring.id);
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

final recurringTransactionProvider =
    AsyncNotifierProvider<
      RecurringTransactionNotifier,
      List<RecurringTransaction>
    >(RecurringTransactionNotifier.new);
