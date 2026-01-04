import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';

void main() {
  Item item = Item(id: 'i1', name: 'Burger', price: 100);
  Type1 type = Type1(id: 't1', type: 'Extra', price: 20);
  Table1 table = Table1(id: 'tb1', tableNo: 5);

  test('Order serializes and deserializes correctly', () {
    final order = Order(
      id: 'o1',
      quantity: 2,
      item: item,
      table: table,
      type: type,
      status: 'open',
      note: 'no onions',
      amount: 240,
    );

    final map = order.toMap();
    final restored = Order.fromMap(map);

    expect(restored, order);
    expect(restored.amount, 240);
  });

  test('Order copyWith overrides selected fields', () {
    final order = Order(
      id: 'o1',
      quantity: 2,
      item: item,
      table: table,
      type: type,
      status: 'open',
      note: '',
      amount: 240,
    );

    final updated = order.copyWith(quantity: 3, amount: 360);

    expect(updated.quantity, 3);
    expect(updated.amount, 360);
    expect(updated.item, item);
  });

  test('Order equality is based on id only', () {
    final o1 = Order(
      id: 'x',
      quantity: 1,
      item: item,
      table: table,
      type: type,
      status: 'open',
      note: '',
      amount: 100,
    );

    final o2 = o1.copyWith(quantity: 10);

    expect(o1, equals(o2));
  });

  test('getData formats order details correctly', () {
    final order = Order(
      id: 'o1',
      quantity: 2,
      item: item,
      table: table,
      type: type,
      status: 'open',
      note: 'extra cheese',
      amount: 240,
    );

    final data = order.getData();

    expect(data.contains('Burger'), true);
    expect(data.contains('Type:'), true);
    expect(data.contains('Quantity: 2'), true);
    expect(data.contains('extra cheese'), true);
  });

  test('getData omits type when type is None', () {
    final noneType = Type1(id: 'n', type: 'None', price: 0);

    final order = Order(
      id: 'o1',
      quantity: 1,
      item: item,
      table: table,
      type: noneType,
      status: 'open',
      note: '',
      amount: 100,
    );

    final data = order.getData();

    expect(data.contains('Type:'), false);
  });
}
