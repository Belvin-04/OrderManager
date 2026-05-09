import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/app_user_remote_data_source.dart';
import 'package:order_manager/repositories/firebase_app_user_repository.dart';

class MockAppUserRemoteDataSource extends Mock
    implements AppUserRemoteDataSource {}

class FakeAppUser extends Fake implements AppUser {}

void main() {
  late FirebaseAppUserRepository repository;
  late MockAppUserRemoteDataSource remote;

  const user = AppUser(id: 'u1', email: 'test@example.com', name: 'Test User');

  setUpAll(() {
    registerFallbackValue(FakeAppUser());
  });

  setUp(() {
    remote = MockAppUserRemoteDataSource();
    repository = FirebaseAppUserRepository(remote);
  });

  group('saveUser', () {
    test('calls remote.saveUser with correct id and map', () async {
      when(() => remote.saveUser(any(), any())).thenAnswer((_) async {});

      await repository.saveUser(user);

      verify(
        () => remote.saveUser('u1', {
          'id': 'u1',
          'email': 'test@example.com',
          'name': 'Test User',
        }),
      ).called(1);
    });
  });

  group('deleteUser', () {
    test('delegates to remote.deleteUser', () async {
      when(() => remote.deleteUser(any())).thenAnswer((_) async {});

      await repository.deleteUser('u1');

      verify(() => remote.deleteUser('u1')).called(1);
    });
  });

  group('watchBusinessUsers', () {
    test('returns empty list when remote emits null', () async {
      when(
        () => remote.watchBusinessUsers(any()),
      ).thenAnswer((_) => Stream.value(null));

      final result = await repository.watchBusinessUsers('biz1').first;

      expect(result, isEmpty);
    }, skip: true);

    test('maps remote data to AppUser list', () async {
      when(() => remote.watchBusinessUsers(any())).thenAnswer(
        (_) => Stream.value({
          'u1': {'id': 'u1', 'email': 'a@example.com', 'name': 'Alice'},
          'u2': {'id': 'u2', 'email': 'b@example.com', 'name': 'Bob'},
        }),
      );

      final result = await repository.watchBusinessUsers('biz1').first;

      expect(result.length, 2);
      expect(result.any((u) => u.name == 'Alice'), isTrue);
      expect(result.any((u) => u.name == 'Bob'), isTrue);
    }, skip: true);

    test('emits multiple events over time', () async {
      final controller = StreamController<Object?>();

      when(
        () => remote.watchBusinessUsers(any()),
      ).thenAnswer((_) => controller.stream);

      final emitted = <List<AppUser>>[];
      final sub = repository.watchBusinessUsers('biz1').listen(emitted.add);

      controller.add(null);
      controller.add({
        'u1': {'id': 'u1', 'email': 'a@example.com', 'name': 'Alice'},
      });
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      await controller.close();

      expect(emitted[0], isEmpty);
      expect(emitted[1].first.name, 'Alice');
    }, skip: true);
  });

  group('queryById', () {
    test('returns null when remote returns null', () async {
      when(() => remote.queryById(any())).thenAnswer((_) async => null);

      final result = await repository.queryById('u1');

      expect(result, isNull);
    });

    test('returns AppUser when remote returns valid data', () async {
      when(() => remote.queryById(any())).thenAnswer(
        (_) async => {
          'u1': {'id': 'u1', 'email': 'test@example.com', 'name': 'Test User'},
        },
      );

      final result = await repository.queryById('u1');

      expect(result, isNotNull);
      expect(result!.id, 'u1');
      expect(result.email, 'test@example.com');
      expect(result.name, 'Test User');
    });

    test('calls remote.queryById with the correct id', () async {
      when(() => remote.queryById(any())).thenAnswer((_) async => null);

      await repository.queryById('u99');

      verify(() => remote.queryById('u99')).called(1);
    });
  });

  group('queryByEmail', () {
    test('returns null when remote returns null', () async {
      when(() => remote.queryByEmail(any())).thenAnswer((_) async => null);

      final result = await repository.queryByEmail('missing@example.com');

      expect(result, isNull);
    });

    test('returns AppUser when remote returns valid data', () async {
      when(() => remote.queryByEmail(any())).thenAnswer(
        (_) async => {
          'u1': {'id': 'u1', 'email': 'test@example.com', 'name': 'Test User'},
        },
      );

      final result = await repository.queryByEmail('test@example.com');

      expect(result, isNotNull);
      expect(result!.email, 'test@example.com');
      expect(result.name, 'Test User');
    });

    test('calls remote.queryByEmail with the correct email', () async {
      when(() => remote.queryByEmail(any())).thenAnswer((_) async => null);

      await repository.queryByEmail('hello@example.com');

      verify(() => remote.queryByEmail('hello@example.com')).called(1);
    });
  });
}
