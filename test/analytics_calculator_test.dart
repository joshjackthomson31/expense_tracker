import 'package:expense_tracker/utils/analytics_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculatePercentageChange', () {
    test('calculates an increase correctly', () {
      expect(calculatePercentageChange(12000, 10000), 20.0);
    });

    test('calculates a decrease correctly', () {
      expect(calculatePercentageChange(8000, 10000), -20.0);
    });

    test('returns null when previous value is zero', () {
      expect(calculatePercentageChange(5000, 0), isNull);
    });
  });
}
