import 'package:expense_tracker/utils/recurrence_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recurring transaction integration rules', () {
    test('the same schedule and due date produce a stable transaction ID', () {
      final firstId = createOccurrenceKey(
        recurringId: 'rent-123',
        dueDate: DateTime(2026, 10, 1),
      );
      final secondId = createOccurrenceKey(
        recurringId: 'rent-123',
        dueDate: DateTime(2026, 10, 1),
      );

      expect(firstId, equals(secondId));
    });

    test('different occurrences produce different transaction IDs', () {
      final octoberId = createOccurrenceKey(
        recurringId: 'rent-123',
        dueDate: DateTime(2026, 10, 1),
      );
      final novemberId = createOccurrenceKey(
        recurringId: 'rent-123',
        dueDate: DateTime(2026, 11, 1),
      );

      expect(octoberId, isNot(equals(novemberId)));
    });

    test('different schedules produce different transaction IDs', () {
      final rentId = createOccurrenceKey(
        recurringId: 'rent-123',
        dueDate: DateTime(2026, 10, 1),
      );
      final salaryId = createOccurrenceKey(
        recurringId: 'salary-456',
        dueDate: DateTime(2026, 10, 1),
      );

      expect(rentId, isNot(equals(salaryId)));
    });
  });
}
