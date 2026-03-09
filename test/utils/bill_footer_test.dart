import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/bills_provider.dart';
import 'package:order_manager/utils/bill_footer.dart';

void main() {
  testWidgets('BillFooter shows quantity and amount from provider', (
    tester,
  ) async {
    final table = Table1(id: 't1', tableNo: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billTotalsProvider(
            '1',
          ).overrideWithValue({'quantity': 3, 'amount': 450}),
        ],
        child: MaterialApp(home: Scaffold(body: BillFooter(table))),
      ),
    );

    expect(find.text('3'), findsOneWidget);

    expect(find.text('450'), findsOneWidget);
  });

  testWidgets('BillFooter defaults to 0 when provider is empty', (
    tester,
  ) async {
    final table = Table1(id: 't1', tableNo: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [billTotalsProvider('1').overrideWithValue({})],
        child: MaterialApp(home: Scaffold(body: BillFooter(table))),
      ),
    );

    expect(find.text('0'), findsNWidgets(2));
  });
}
