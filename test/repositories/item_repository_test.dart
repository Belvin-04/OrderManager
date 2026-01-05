import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'in_memory/in_memory_item_repository.dart';

void main() {
  late InMemoryItemRepository repo;

  setUp(() {
    repo = InMemoryItemRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('empty repository emits empty list immediately', () async {
    final items = await repo.watchItems().first;
    expect(items, isEmpty);
  });

  test('saveItem and getItem work', () async {
    final item = Item(id: '', name: 'Burger', price: 100);

    await repo.saveItem(item);

    final fetched = await repo.getItem('Burger');
    expect(fetched, isNotNull);
    expect(fetched!.price, 100);
  });

  test('saveItem overwrites existing item by name and reuses id', () async {
    await repo.saveItem(Item(id: '', name: 'Burger', price: 100));
    await repo.saveItem(Item(id: '', name: 'Burger', price: 150));

    final items = await repo.watchItems().first;

    expect(items.length, 1);
    expect(items.first.price, 150);
  });

  test('deleteItem removes item and emits update', () async {
    final item = Item(id: '', name: 'Burger', price: 100);
    await repo.saveItem(item);

    final saved = await repo.getItem('Burger');
    await repo.deleteItem(saved!);

    final items = await repo.watchItems().first;
    expect(items, isEmpty);
  });

  test('getItem returns null if item does not exist', () async {
    final fetched = await repo.getItem('Pizza');
    expect(fetched, isNull);
  });

  test('watchItems emits when data changes', () async {
    final future = repo.watchItems().skip(1).first;

    await repo.saveItem(Item(id: '', name: 'Burger', price: 100));

    final items = await future;
    expect(items.length, 1);
    expect(items.first.name, 'Burger');
  });
}
