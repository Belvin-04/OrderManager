import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/providers/item_providers.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/repositories/abstract_files/items_repository.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/views/items/item_delete_dialog.dart';
import 'package:order_manager/views/items/item_edit_dialog.dart';
import 'package:order_manager/views/items/items.dart';

class MockItemsRepository extends Mock implements ItemsRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class FakeItem extends Fake implements Item {}

class FakeOrder extends Fake implements Order {}

Future<void> pumpItemsScreen(
  WidgetTester tester, {
  required List<Item> items,
}) async {
  final repo = MockItemsRepository();
  when(repo.watchItems).thenAnswer((_) => Stream.value(items));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [itemRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Items()),
    ),
  );

  await tester.pump();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeItem());
    registerFallbackValue(FakeOrder());
  });

  testWidgets('shows loading indicator initially', (tester) async {
    final repo = MockItemsRepository();
    when(repo.watchItems).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Items()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when itemsProvider errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsProvider.overrideWith(
            (ref) => Stream<List<Item>>.error('error'),
          ),
        ],
        child: const MaterialApp(home: Items()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Error: error'), findsOneWidget);
  });

  testWidgets('shows No Items when list is empty', (tester) async {
    await pumpItemsScreen(tester, items: []);

    expect(find.text('No Items'), findsOneWidget);
  });

  testWidgets('renders list of items', (tester) async {
    await pumpItemsScreen(
      tester,
      items: [
        Item(id: '1', name: 'Burger', price: 100),
        Item(id: '2', name: 'Pizza', price: 200),
      ],
    );

    expect(find.text('Name: Burger'), findsOneWidget);
    expect(find.text('Price: 100'), findsOneWidget);
    expect(find.text('Name: Pizza'), findsOneWidget);
    expect(find.text('Price: 200'), findsOneWidget);
  });

  testWidgets('FAB opens add item dialog', (tester) async {
    await pumpItemsScreen(tester, items: []);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(ItemEditDialog), findsOneWidget);
  });

  testWidgets('edit icon opens edit dialog with item data', (tester) async {
    await pumpItemsScreen(
      tester,
      items: [Item(id: '1', name: 'Burger', price: 100)],
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(ItemEditDialog), findsOneWidget);
    expect(find.text('Burger'), findsOneWidget);
  });

  testWidgets('delete icon opens delete dialog', (tester) async {
    await pumpItemsScreen(
      tester,
      items: [Item(id: '1', name: 'Burger', price: 100)],
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDeleteDialog), findsOneWidget);
  });

  testWidgets('confirm delete calls deleteItem and shows snackbar', (
    tester,
  ) async {
    final repo = MockItemsRepository();
    final item = Item(id: '1', name: 'Burger', price: 100);
    when(repo.watchItems).thenAnswer((_) => Stream.value([item]));
    when(() => repo.deleteItem(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Items()),
      ),
    );

    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Item Deleted Successfully'), findsOneWidget);
    verify(() => repo.deleteItem(item)).called(1);
  });

  testWidgets('saving item saves item and shows snackbar', (tester) async {
    final repo = MockItemsRepository();
    final orderRepo = MockOrderRepository();
    final item = Item(id: '1', name: 'Burger', price: 100);

    when(repo.watchItems).thenAnswer((_) => Stream.value([item]));
    when(() => repo.saveItem(any())).thenAnswer((_) async {});
    when(() => orderRepo.getOrdersByItem(any())).thenAnswer((_) async => []);
    when(() => orderRepo.saveOrder(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(repo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: const MaterialApp(home: Items()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(ItemEditDialog), findsOneWidget);
    await tester.tap(find.text('Save Item'));
    await tester.pumpAndSettle();
    verify(() => repo.saveItem(item)).called(1);
    expect(find.text('Item Saved Successfully...'), findsOneWidget);
  });
}
