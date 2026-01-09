import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/utils/bill_item.dart';

void main() {
  testWidgets('BillItem displays all values correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BillItem('Burger', '2', '₹200', '₹100')),
      ),
    );

    expect(find.text('Burger'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('₹200'), findsOneWidget);
    expect(find.text('₹100'), findsOneWidget);
  });

  testWidgets('BillItem uses four Expanded widgets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BillItem('Pizza', '1', '₹300', '₹300')),
      ),
    );

    expect(find.byType(Expanded), findsNWidgets(4));
    expect(find.byType(Row), findsOneWidget);
  });
}
