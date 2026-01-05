import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/type.dart';

Type1 buildType({String id = 'ty1', String type = 'Extra', int price = 20}) {
  return Type1(id: id, type: type, price: price);
}

void main() {
  test('Type1 toMap converts type to correct map structure', () {
    final type = buildType();

    final map = type.toMap();

    expect(map['id'], 'ty1');
    expect(map['type'], 'Extra');
    expect(map['price'], 20);
  });

  test('Type1 fromMap creates Type1 from map', () {
    final map = {'id': 'ty1', 'type': 'Extra', 'price': 20};

    final type = Type1.fromMap(map);

    expect(type.id, 'ty1');
    expect(type.type, 'Extra');
    expect(type.price, 20);
  });

  test('Type1 serializes and deserializes correctly', () {
    final type = Type1(id: 't1', type: 'Extra', price: 20);

    final map = type.toMap();
    final restored = Type1.fromMap(map);

    expect(restored, type);
    expect(restored.price, 20);
  });

  test('Type1 copyWith overrides selected fields', () {
    final type = Type1(id: 't1', type: 'Extra', price: 20);

    final updated = type.copyWith(price: 30);

    expect(updated.id, 't1');
    expect(updated.type, 'Extra');
    expect(updated.price, 30);
  });

  test('Type1 equality is based on id only', () {
    final t1 = Type1(id: 'x', type: 'A', price: 10);
    final t2 = Type1(id: 'x', type: 'B', price: 20);

    expect(t1, equals(t2));
    expect(t1.hashCode, t2.hashCode);
  });

  test('getType returns empty string for None when flag is 0', () {
    final type = Type1(id: 'n', type: 'None', price: 0);

    expect(type.getType(0), '');
    expect(type.getType(1), 'None');
  });

  test('toString contains type and price', () {
    final type = Type1(id: 't1', type: 'Extra', price: 20);

    final text = type.toString();

    expect(text.contains('Extra'), true);
    expect(text.contains('20'), true);
  });
}
