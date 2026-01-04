import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';

void main() {
  test('Item.toMap returns correct map', () {
    final item = Item(id: '1', name: 'Burger', price: 100);

    final map = item.toMap();

    expect(map['id'], '1');
    expect(map['name'], 'Burger');
    expect(map['price'], 100);
  });

  test('Item.fromMap creates correct Item', () {
    final map = {'id': '1', 'name': 'Burger', 'price': 100};

    final item = Item.fromMap(map);

    expect(item.id, '1');
    expect(item.name, 'Burger');
    expect(item.price, 100);
  });

  test('Item serialization round-trip retains data', () {
    final original = Item(id: '1', name: 'Burger', price: 100);

    final map = original.toMap();
    final reconstructed = Item.fromMap(map);

    expect(reconstructed, original);
    expect(reconstructed.price, original.price);
  });

  test('Item.copyWith overrides only provided fields', () {
    final item = Item(id: '1', name: 'Burger', price: 100);

    final updated = item.copyWith(price: 150);

    expect(updated.id, '1');
    expect(updated.name, 'Burger');
    expect(updated.price, 150);
  });

  test('Items with same id are equal', () {
    final item1 = Item(id: '1', name: 'Burger', price: 100);

    final item2 = Item(id: '1', name: 'Burger Deluxe', price: 150);

    expect(item1, equals(item2));
    expect(item1.hashCode, item2.hashCode);
  });

  test('Items with different ids are not equal', () {
    final item1 = Item(id: '1', name: 'Burger', price: 100);

    final item2 = Item(id: '2', name: 'Burger', price: 100);

    expect(item1 == item2, false);
  });

  test('Item.toString contains name and price', () {
    final item = Item(id: '1', name: 'Burger', price: 100);

    final text = item.toString();

    expect(text.contains('Burger'), true);
    expect(text.contains('100'), true);
  });
}
