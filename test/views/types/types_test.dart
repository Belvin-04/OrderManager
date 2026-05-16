import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/employee_provider.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/type_providers.dart';
import 'package:order_manager/views/types/type_delete_dialog.dart';
import 'package:order_manager/views/types/type_edit_dialog.dart';
import 'package:order_manager/views/types/types.dart';

import '../../test_helper.dart';

Future<void> pumpTypesScreen(
  WidgetTester tester, {
  required List<Type1> types,
}) async {
  final repo = MockTypeRepository();
  when(repo.watchTypes).thenAnswer((_) => Stream.value(types));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [typeRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Types()),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeType1());
    registerFallbackValue(FakeOrder());
  });
  testWidgets('shows loading indicator initially', (tester) async {
    final repo = MockTypeRepository();
    when(repo.watchTypes).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [typeRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Types()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when typesProvider errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typesProvider.overrideWith(
            (ref) => Stream<List<Type1>>.error('error'),
          ),
        ],
        child: const MaterialApp(home: Types()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Error: error'), findsOneWidget);
  });

  testWidgets('shows No Types when list is empty', (tester) async {
    await pumpTypesScreen(tester, types: []);

    expect(find.text('No Types'), findsOneWidget);
  });

  testWidgets('renders list of types', (tester) async {
    await pumpTypesScreen(
      tester,
      types: [
        Type1(id: '1', type: 'Extra', price: 20),
        Type1(id: '2', type: 'Cheese', price: 30),
      ],
    );

    expect(find.text('Type: Extra'), findsOneWidget);
    expect(find.text('Price: 20'), findsOneWidget);
    expect(find.text('Type: Cheese'), findsOneWidget);
    expect(find.text('Price: 30'), findsOneWidget);
  });

  testWidgets('FAB opens add type dialog', (tester) async {
    await pumpTypesScreen(tester, types: []);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(TypeEditDialog), findsOneWidget);
  });

  testWidgets('edit icon opens edit dialog', (tester) async {
    await pumpTypesScreen(
      tester,
      types: [Type1(id: '1', type: 'Extra', price: 20)],
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(TypeEditDialog), findsOneWidget);
    expect(find.text('Extra'), findsOneWidget);
  });

  testWidgets('delete icon opens delete dialog', (tester) async {
    await pumpTypesScreen(
      tester,
      types: [Type1(id: '1', type: 'Extra', price: 20)],
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(TypeDeleteDialog), findsOneWidget);
  });

  testWidgets('confirming delete deletes type and shows snackbar', (
    tester,
  ) async {
    final repo = MockTypeRepository();
    final orderRepo = MockOrderRepository();
    final type = Type1(id: '1', type: 'Extra', price: 20);
    when(repo.watchTypes).thenAnswer((_) => Stream.value([type]));
    when(() => repo.deleteType(any())).thenAnswer((_) async {});
    when(() => orderRepo.getOrdersByType(any())).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typeRepositoryProvider.overrideWithValue(repo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: const MaterialApp(home: Types()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(TypeDeleteDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    verify(() => repo.deleteType(type)).called(1);
    expect(find.text('Type Deleted Successfully'), findsOneWidget);
  });

  testWidgets('delete type fails if orders exist', (tester) async {
    final repo = MockTypeRepository();
    final orderRepo = MockOrderRepository();
    final type = Type1(id: '1', type: 'Extra', price: 20);
    when(repo.watchTypes).thenAnswer((_) => Stream.value([type]));
    when(
      () => orderRepo.getOrdersByType(any()),
    ).thenAnswer((_) async => [baseOrder(type: type)]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typeRepositoryProvider.overrideWithValue(repo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: const MaterialApp(home: Types()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      find.text('Order with this type exists, cannot be deleted'),
      findsOneWidget,
    );
    verifyNever(() => repo.deleteType(any()));
  });

  testWidgets('saving type saves type and shows snackbar', (tester) async {
    final repo = MockTypeRepository();
    final orderRepo = MockOrderRepository();
    final type = Type1(id: '1', type: 'Extra', price: 20);
    when(repo.watchTypes).thenAnswer((_) => Stream.value([type]));
    when(() => repo.saveType(any())).thenAnswer((_) async {});
    when(() => orderRepo.getOrdersByType(any())).thenAnswer((_) async => []);
    when(() => orderRepo.saveOrder(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typeRepositoryProvider.overrideWithValue(repo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: const MaterialApp(home: Types()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(TypeEditDialog), findsOneWidget);
    await tester.tap(find.text('Save Type'));
    await tester.pumpAndSettle();
    verify(() => repo.saveType(type)).called(1);
    expect(find.text('Type Saved Successfully...'), findsOneWidget);
  });

  testWidgets('FAB and edit/delete icons are hidden for employee', (
    tester,
  ) async {
    final repo = MockTypeRepository();
    final type = Type1(id: '1', type: 'Extra', price: 20);
    when(repo.watchTypes).thenAnswer((_) => Stream.value([type]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typeRepositoryProvider.overrideWithValue(repo),
          isEmployeeProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(home: Types()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
  });
}
