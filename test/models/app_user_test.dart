import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/app_user.dart';

void main() {
  group('AppUser', () {
    const user = AppUser(
      id: 'u1',
      email: 'test@example.com',
      name: 'Test User',
    );

    test('toMap returns correct map', () {
      final map = user.toMap();
      expect(map, {
        'id': 'u1',
        'email': 'test@example.com',
        'name': 'Test User',
      });
    });

    test('fromMap returns correct AppUser', () {
      final map = {
        'id': 'u1',
        'email': 'test@example.com',
        'name': 'Test User',
      };
      final fromMap = AppUser.fromMap(map);
      expect(fromMap, user);
    });

    test('fromMap uses empty strings for missing fields', () {
      final fromMap = AppUser.fromMap({});
      expect(fromMap.id, '');
      expect(fromMap.email, '');
      expect(fromMap.name, '');
    });

    test('copyWith updates specified fields', () {
      final updated = user.copyWith(name: 'New Name');
      expect(updated.id, 'u1');
      expect(updated.email, 'test@example.com');
      expect(updated.name, 'New Name');

      final updatedId = user.copyWith(id: 'u2');
      expect(updatedId.id, 'u2');
      expect(updatedId.email, 'test@example.com');
      expect(updatedId.name, 'Test User');
    });

    test('toString returns formatted string', () {
      expect(user.toString(), 'Test User\ntest@example.com');
    });

    test('equality works based on id', () {
      const user2 = AppUser(
        id: 'u1',
        email: 'other@example.com',
        name: 'Other Name',
      );
      const user3 = AppUser(
        id: 'u2',
        email: 'test@example.com',
        name: 'Test User',
      );

      expect(user == user2, isTrue);
      expect(user == user3, isFalse);
    });

    test('hashCode works based on id', () {
      const user2 = AppUser(
        id: 'u1',
        email: 'other@example.com',
        name: 'Other Name',
      );
      expect(user.hashCode, user2.hashCode);
    });
  });
}
