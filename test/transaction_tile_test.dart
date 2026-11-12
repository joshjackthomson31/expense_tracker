import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/payment_method.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('transaction tile fits a narrow screen and remains tappable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    final transaction = Transaction(
      id: 'transaction-1',
      name: 'A very long transaction name that needs truncation',
      amount: 1234567890.12,
      type: TransactionType.expense,
      expenseCategory: ExpenseCategory.transport,
      date: DateTime(2026, 10, 26),
      paymentMethod: PaymentMethod.creditCard,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionTile(
            transaction: transaction,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text(transaction.name), findsOneWidget);
    expect(find.text('Transport • Credit Card'), findsOneWidget);
    expect(find.text('26 Oct 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });
}
