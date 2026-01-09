import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/items/item_delete_dialog.dart';
import 'package:order_manager/views/items/item_edit_dialog.dart';
import 'package:order_manager/views/items/items.dart';

import '../../repositories/in_memory/in_memory_item_repository.dart';
import '../fake_viewmodel/fake_items_viewmodel.dart';

Future<void> pumpItemsScreen(
  WidgetTester tester, {
  required InMemoryItemRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [itemRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Items()),
    ),
  );

  await tester.pump();
}

void main() {
  testWidgets('shows loading indicator initially', (tester) async {
    final repo = InMemoryItemRepository();

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
    final repo = InMemoryItemRepository();

    await pumpItemsScreen(tester, repo: repo);

    expect(find.text('No Items'), findsOneWidget);
  });

  testWidgets('renders list of items', (tester) async {
    final repo = InMemoryItemRepository();

    await repo.saveItem(Item(id: '1', name: 'Burger', price: 100));
    await repo.saveItem(Item(id: '2', name: 'Pizza', price: 200));

    await pumpItemsScreen(tester, repo: repo);

    expect(find.text('Name: Burger'), findsOneWidget);
    expect(find.text('Price: 100'), findsOneWidget);
    expect(find.text('Name: Pizza'), findsOneWidget);
    expect(find.text('Price: 200'), findsOneWidget);
  });

  testWidgets('FAB opens add item dialog', (tester) async {
    final repo = InMemoryItemRepository();

    await pumpItemsScreen(tester, repo: repo);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(ItemEditDialog), findsOneWidget);
  });

  testWidgets('edit icon opens edit dialog with item data', (tester) async {
    final repo = InMemoryItemRepository();
    final item = Item(id: '1', name: 'Burger', price: 100);

    await repo.saveItem(item);
    await pumpItemsScreen(tester, repo: repo);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(ItemEditDialog), findsOneWidget);
    expect(find.text('Burger'), findsOneWidget);
  });

  testWidgets('delete icon opens delete dialog', (tester) async {
    final repo = InMemoryItemRepository();
    final item = Item(id: '1', name: 'Burger', price: 100);

    await repo.saveItem(item);
    await pumpItemsScreen(tester, repo: repo);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDeleteDialog), findsOneWidget);
  });

  testWidgets('confirm delete calls deleteItem and shows snackbar', (
    tester,
  ) async {
    final repo = InMemoryItemRepository();
    final item = Item(id: '1', name: 'Burger', price: 100);

    final fakeViewModelProvider = FakeItemsViewmodel();

    await repo.saveItem(item);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(repo),
          itemsViewModelProvider.overrideWith(() => fakeViewModelProvider),
        ],
        child: const MaterialApp(home: Items()),
      ),
    );

    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Item Deleted Successfully'), findsOneWidget);
  });

  testWidgets('saving item saves item and shows snackbar', (tester) async {
    final repo = InMemoryItemRepository();
    final item = Item(id: '1', name: 'Burger', price: 100);
    await repo.saveItem(item);

    final fakeViewModel = FakeItemsViewmodel();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(repo),
          itemsViewModelProvider.overrideWith(() => fakeViewModel),
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
    expect(fakeViewModel.savedItem, item);
    expect(find.text('Item Saved Successfully...'), findsOneWidget);
  });
}
