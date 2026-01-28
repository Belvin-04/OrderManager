import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/bills/bills.dart';
import 'package:order_manager/views/home_page/home_page.dart';

import '../fake_viewmodel/fake_orders_viewmodel.dart';

Future<void> pumpOrdersScreen(
  WidgetTester tester, {
  required FakeOrdersViewModel fakeViewModel,
}) async {
  final table = Table1(id: 't1', tableNo: 1);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ordersViewModelProvider.overrideWith(() => fakeViewModel),
        tablesProvider.overrideWithValue(AsyncData([table])),
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );

  await tester.tap(find.byIcon(Icons.event_note_outlined));

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows all order tabs', (tester) async {
    final fakeVM = FakeOrdersViewModel(stream: const Stream.empty());

    await pumpOrdersScreen(tester, fakeViewModel: fakeVM);

    expect(find.text('Pending Orders'), findsOneWidget);
    expect(find.text('Completed Orders'), findsOneWidget);
    expect(find.text('Canceled Orders'), findsOneWidget);
  });

  testWidgets('repeat all shows success snackbar', (tester) async {
    final fakeVM = FakeOrdersViewModel(stream: const Stream.empty())
      ..repeatResult = true;

    await pumpOrdersScreen(tester, fakeViewModel: fakeVM);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Repeat all'));
    await tester.pumpAndSettle();

    expect(fakeVM.repeatCalled, true);
    expect(find.text('All orders repeated successfully...!'), findsOneWidget);
  });

  testWidgets('repeat all shows empty snackbar when no orders', (tester) async {
    final fakeVM = FakeOrdersViewModel(stream: const Stream.empty())
      ..repeatResult = false;

    await pumpOrdersScreen(tester, fakeViewModel: fakeVM);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Repeat all'));
    await tester.pumpAndSettle();

    expect(find.text('There are no orders to repeat...!'), findsOneWidget);
  });

  testWidgets('restore all shows success snackbar', (tester) async {
    final fakeVM = FakeOrdersViewModel(stream: const Stream.empty())
      ..restoreResult = true;

    await pumpOrdersScreen(tester, fakeViewModel: fakeVM);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore all'));
    await tester.pumpAndSettle();

    expect(fakeVM.restoreCalled, true);
    expect(find.text('All orders restored successfully...!'), findsOneWidget);
  });

  testWidgets('restore all shows empty snackbar when no orders', (
    tester,
  ) async {
    final fakeVM = FakeOrdersViewModel(stream: const Stream.empty())
      ..restoreResult = false;

    await pumpOrdersScreen(tester, fakeViewModel: fakeVM);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore all'));
    await tester.pumpAndSettle();

    expect(fakeVM.restoreCalled, true);
    expect(find.text('There are no canceled orders...!'), findsOneWidget);
  });

  testWidgets('bill option navigates to Bills screen', (tester) async {
    final fakeVM = FakeOrdersViewModel(stream: const Stream.empty());

    await pumpOrdersScreen(tester, fakeViewModel: fakeVM);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bill'));
    await tester.pumpAndSettle();

    expect(find.byType(Bills), findsOneWidget);
  });

  testWidgets('back button navigates to home page', (tester) async {
    final fakeVM = FakeOrdersViewModel(stream: const Stream.empty());

    await pumpOrdersScreen(tester, fakeViewModel: fakeVM);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('back navigation button redirects to HomePage', (tester) async {
    final fakeVM = FakeOrdersViewModel(stream: const Stream.empty());
    await pumpOrdersScreen(tester, fakeViewModel: fakeVM);

    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
}
