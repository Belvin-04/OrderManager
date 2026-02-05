import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/views/home_page/total_amount.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class FakeOrder extends Fake implements Order {}

Future<void> pumpTotalAmount(
  WidgetTester tester,
  MockOrderRepository orderRepo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [orderRepositoryProvider.overrideWithValue(orderRepo)],
      child: MaterialApp(
        home: Scaffold(
          body: TotalAmount(table: Table1(id: 't1', tableNo: 1)),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOrder());
  });
  testWidgets('renders nothing when stream has no data', (tester) async {
    final orderRepo = MockOrderRepository();
    when(
      () =>
          orderRepo.getTotalAmountForTable('1', splitNo: any(named: 'splitNo')),
    ).thenAnswer((_) => const Stream<int>.empty());
    await pumpTotalAmount(tester, orderRepo);

    await tester.pump();

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('renders nothing when total is 0', (tester) async {
    final orderRepo = MockOrderRepository();
    when(
      () =>
          orderRepo.getTotalAmountForTable('1', splitNo: any(named: 'splitNo')),
    ).thenAnswer((_) => Stream<int>.value(0));
    await pumpTotalAmount(tester, orderRepo);

    await tester.pumpAndSettle();

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('shows total amount when value is greater than zero', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();
    when(
      () =>
          orderRepo.getTotalAmountForTable('1', splitNo: any(named: 'splitNo')),
    ).thenAnswer((_) => Stream<int>.value(150));
    await pumpTotalAmount(tester, orderRepo);

    await tester.pumpAndSettle();

    expect(find.text('₹150'), findsOneWidget);
  });

  testWidgets('updates amount when stream emits new values', (tester) async {
    final orderRepo = MockOrderRepository();
    final controller = StreamController<int>();

    when(
      () =>
          orderRepo.getTotalAmountForTable('1', splitNo: any(named: 'splitNo')),
    ).thenAnswer((_) => controller.stream);

    await pumpTotalAmount(tester, orderRepo);

    controller.add(100);
    await tester.pump();

    expect(find.text('₹100'), findsOneWidget);

    controller.add(250);
    await tester.pumpAndSettle();

    expect(find.text('₹250'), findsOneWidget);

    await controller.close();
  });
}
