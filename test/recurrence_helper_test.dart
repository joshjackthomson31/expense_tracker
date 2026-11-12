import 'package:expense_tracker/models/recurring_transaction.dart';
import 'package:expense_tracker/utils/recurrence_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateNextDueDate', () {
    test('adds one day for daily recurrence', () {
      expect(
        calculateNextDueDate(
          currentDueDate: DateTime(2026, 10, 12),
          frequency: RecurrenceFrequency.daily,
          preferredDay: 12,
        ),
        DateTime(2026, 10, 13),
      );
    });

    test('adds seven days for weekly recurrence', () {
      expect(
        calculateNextDueDate(
          currentDueDate: DateTime(2026, 10, 12),
          frequency: RecurrenceFrequency.weekly,
          preferredDay: 12,
        ),
        DateTime(2026, 10, 19),
      );
    });

    test('clamps monthly recurrence to the last day of a short month', () {
      expect(
        calculateNextDueDate(
          currentDueDate: DateTime(2026, 1, 31),
          frequency: RecurrenceFrequency.monthly,
          preferredDay: 31,
        ),
        DateTime(2026, 2, 28),
      );
    });

    test('preserves the preferred monthly day after a short month', () {
      final february = calculateNextDueDate(
        currentDueDate: DateTime(2026, 2, 28),
        frequency: RecurrenceFrequency.monthly,
        preferredDay: 31,
      );
      expect(february, DateTime(2026, 3, 31));
    });

    test('returns to the preferred day after February in a leap year', () {
      expect(
        calculateNextDueDate(
          currentDueDate: DateTime(2028, 2, 28),
          frequency: RecurrenceFrequency.monthly,
          preferredDay: 31,
        ),
        DateTime(2028, 3, 31),
      );
    });

    test('preserves time when clamping a month-end date', () {
      expect(
        calculateNextDueDate(
          currentDueDate: DateTime(2026, 1, 31, 8, 15, 30, 250, 400),
          frequency: RecurrenceFrequency.monthly,
          preferredDay: 31,
        ),
        DateTime(2026, 2, 28, 8, 15, 30, 250, 400),
      );
    });

    test('handles leap-day yearly recurrence in a non-leap year', () {
      expect(
        calculateNextDueDate(
          currentDueDate: DateTime(2024, 2, 29),
          frequency: RecurrenceFrequency.yearly,
          preferredDay: 29,
        ),
        DateTime(2025, 2, 28),
      );
    });

    test('returns to February 29 in the next leap year', () {
      expect(
        calculateNextDueDate(
          currentDueDate: DateTime(2031, 2, 28),
          frequency: RecurrenceFrequency.yearly,
          preferredDay: 29,
        ),
        DateTime(2032, 2, 29),
      );
    });

    test('preserves time for yearly occurrences', () {
      expect(
        calculateNextDueDate(
          currentDueDate: DateTime(2026, 6, 15, 8, 15, 30, 250, 400),
          frequency: RecurrenceFrequency.yearly,
          preferredDay: 15,
        ),
        DateTime(2027, 6, 15, 8, 15, 30, 250, 400),
      );
    });
  });

  test('creates a stable occurrence key for a calendar date', () {
    expect(
      createOccurrenceKey(
        recurringId: 'rent-123',
        dueDate: DateTime(2026, 3, 5),
      ),
      'rent-123_2026-03-05',
    );
  });

  test('different dates and schedules produce distinct occurrence keys', () {
    final original = createOccurrenceKey(
      recurringId: 'rent-123',
      dueDate: DateTime(2026, 3, 5),
    );

    expect(
      createOccurrenceKey(
        recurringId: 'rent-123',
        dueDate: DateTime(2026, 3, 6),
      ),
      isNot(original),
    );
    expect(
      createOccurrenceKey(
        recurringId: 'rent-124',
        dueDate: DateTime(2026, 3, 5),
      ),
      isNot(original),
    );
  });
}
