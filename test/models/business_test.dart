import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/business.dart';

void main() {
  const business = Business(id: 'b1', name: 'Test Business', ownerId: 'owner1');

  group('Business', () {
    test('constructor sets values correctly', () {
      expect(business.id, 'b1');

      expect(business.name, 'Test Business');

      expect(business.ownerId, 'owner1');
    });

    test('ownerId defaults to empty string', () {
      const business = Business(id: 'b1', name: 'Test Business');

      expect(business.ownerId, '');
    });

    test('toMap returns correct map', () {
      final map = business.toMap();

      expect(map, {'id': 'b1', 'name': 'Test Business', 'ownerId': 'owner1'});
    });

    test('fromMap creates Business correctly', () {
      final business = Business.fromMap({
        'id': 'b1',
        'name': 'Test Business',
        'ownerId': 'owner1',
      });

      expect(business.id, 'b1');

      expect(business.name, 'Test Business');

      expect(business.ownerId, 'owner1');
    });

    test('fromMap uses empty strings for missing values', () {
      final business = Business.fromMap({});

      expect(business.id, '');

      expect(business.name, '');

      expect(business.ownerId, '');
    });

    test('copyWith updates selected fields only', () {
      final updated = business.copyWith(name: 'Updated Business');

      expect(updated.id, 'b1');

      expect(updated.name, 'Updated Business');

      expect(updated.ownerId, 'owner1');
    });

    test('copyWith can update all fields', () {
      final updated = business.copyWith(
        id: 'b2',
        name: 'New Business',
        ownerId: 'owner2',
      );

      expect(updated.id, 'b2');

      expect(updated.name, 'New Business');

      expect(updated.ownerId, 'owner2');
    });

    test('toString returns correct format', () {
      expect(business.toString(), 'Business(id: b1, name: Test Business)');
    });

    test('equality is based on id', () {
      const business1 = Business(id: 'b1', name: 'Business One');

      const business2 = Business(id: 'b1', name: 'Different Name');

      expect(business1, business2);
    });

    test('hashCode is based on id', () {
      const business1 = Business(id: 'b1', name: 'Business One');

      const business2 = Business(id: 'b1', name: 'Different Name');

      expect(business1.hashCode, business2.hashCode);
    });

    test('businesses with different ids are not equal', () {
      const business1 = Business(id: 'b1', name: 'Business One');

      const business2 = Business(id: 'b2', name: 'Business One');

      expect(business1 == business2, false);
    });
  });
}
