import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';

Order buildOrder({
  String id = 'o1',
  int quantity = 2,
  int amount = 240,
  String status = 'pending',
  String note = 'extra cheese',
}) {
  return Order(
    id: id,
    quantity: quantity,
    amount: amount,
    status: status,
    note: note,
    item: Item(id: 'i1', name: 'Burger', price: 100),
    type: Type1(id: 't1', type: 'Extra', price: 20),
    table: Table1(id: 'tb1', tableNo: 1),
  );
}

void main() {
  Item item = Item(id: 'i1', name: 'Burger', price: 100);
  Type1 type = Type1(id: 't1', type: 'Extra', price: 20);
  Table1 table = Table1(id: 'tb1', tableNo: 5);

  test('Order toMap converts order to correct map structure', () {
    final order = buildOrder();

    final map = order.toMap();

    expect(map['id'], 'o1');
    expect(map['quantity'], 2);
    expect(map['status'], 'pending');
    expect(map['note'], 'extra cheese');
    expect(map['amount'], 240);

    expect(map['item'], isA<Map<String, dynamic>>());
    expect(map['type'], isA<Map<String, dynamic>>());
    expect(map['table'], isA<Map<String, dynamic>>());

    expect(map['item']['name'], 'Burger');
    expect(map['type']['type'], 'Extra');
    expect(map['table']['tableNo'], 1);
  });

  test('Order fromMap recreates identical Order from map', () {
    final original = buildOrder();

    final map = original.toMap();
    final recreated = Order.fromMap(map);

    expect(recreated.id, original.id);
    expect(recreated.quantity, original.quantity);
    expect(recreated.amount, original.amount);
    expect(recreated.status, original.status);
    expect(recreated.note, original.note);

    expect(recreated.item, original.item);
    expect(recreated.type, original.type);
    expect(recreated.table, original.table);
  });

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
    expect(o1.hashCode, o2.hashCode);
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

  test('Order toString returns formatted order details', () {
    final order = buildOrder();

    final result = order.toString();

    expect(result, contains('Id: o1'));
    expect(result, contains('Quantity: 2'));
    expect(result, contains('Item Name: Burger'));
    expect(result, contains('Table No: 1'));
    expect(result, contains('Type: Extra'));
    expect(result, contains('Note: extra cheese'));
    expect(result, contains('Status: pending'));
    expect(result, contains('Amount: 240'));
  });
}
