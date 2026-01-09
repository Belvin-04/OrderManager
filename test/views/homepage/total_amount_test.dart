import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/home_page/total_amount.dart';

import '../fake_viewmodel/fake_orders_viewmodel.dart';

Future<void> pumpTotalAmount(
  WidgetTester tester, {
  required Stream<int> stream,
}) async {
  final fakeVm = FakeOrdersViewModel(stream: stream);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [ordersViewModelProvider.overrideWith(() => fakeVm)],
      child: MaterialApp(
        home: Scaffold(
          body: TotalAmount(table: Table1(id: 't1', tableNo: 1)),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders nothing when stream has no data', (tester) async {
    await pumpTotalAmount(tester, stream: const Stream<int>.empty());

    await tester.pump();

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('renders nothing when total is 0', (tester) async {
    await pumpTotalAmount(tester, stream: Stream.value(0));

    await tester.pumpAndSettle();

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('shows total amount when value is greater than zero', (
    tester,
  ) async {
    await pumpTotalAmount(tester, stream: Stream.value(150));

    await tester.pumpAndSettle();

    expect(find.text('₹150'), findsOneWidget);
  });

  testWidgets('updates amount when stream emits new values', (tester) async {
    final controller = StreamController<int>();

    await pumpTotalAmount(tester, stream: controller.stream);

    controller.add(100);
    await tester.pump();

    expect(find.text('₹100'), findsOneWidget);

    controller.add(250);
    await tester.pumpAndSettle();

    expect(find.text('₹250'), findsOneWidget);

    await controller.close();
  });
}
