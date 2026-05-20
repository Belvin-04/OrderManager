import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/app_user_remote_data_source.dart';
import 'package:order_manager/repositories/firebase_app_user_repository.dart';

import '../test_helper.dart';

class MockAppUserRemoteDataSource extends Mock
    implements AppUserRemoteDataSource {}

void main() {
  late FirebaseAppUserRepository repository;
  late MockAppUserRemoteDataSource remote;

  const user = AppUser(id: 'u1', email: 'test@example.com', name: 'Test User');

  setUpAll(() {
    registerFallbackValue(FakeAppUser());
    registerFallbackValue(FakeBusinessEmployee());
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

  group('watchBusinessEmployees', () {
    test('returns empty list when remote emits null', () async {
      when(
        () => remote.watchBusinessEmployees(any()),
      ).thenAnswer((_) => Stream.value(null));

      final result = await repository.watchBusinessEmployees('biz1').first;

      expect(result, isEmpty);
    });

    test('maps remote data to BusinessEmployee list', () async {
      when(() => remote.watchBusinessEmployees(any())).thenAnswer(
        (_) => Stream.value({
          'r1': {
            'relationId': 'r1',
            'businessId': 'b1',
            'businessName': 'b1',
            'employeeId': 'e1',
            'employeeName': 'e1',
            'employeeEmail': 'e1@email.com',
            'employeeRole': 'e1',
          },
          'r2': {
            'relationId': 'r2',
            'businessId': 'b1',
            'businessName': 'b1',
            'employeeId': 'e2',
            'employeeName': 'e2',
            'employeeEmail': 'e2@email.com',
            'employeeRole': 'e2',
          },
        }),
      );

      final result = await repository.watchBusinessEmployees('b1').first;

      expect(result.length, 2);
      expect(result.any((u) => u.employeeName == 'e1'), isTrue);
      expect(result.any((u) => u.employeeName == 'e2'), isTrue);
    });

    test('emits multiple events over time', () async {
      final controller = StreamController<Object?>();

      when(
        () => remote.watchBusinessEmployees(any()),
      ).thenAnswer((_) => controller.stream);

      final emitted = <List<BusinessEmployee>>[];
      final sub = repository.watchBusinessEmployees('biz1').listen(emitted.add);

      controller.add(null);
      controller.add({
        'r1': {
          'relationId': 'r1',
          'businessId': 'b1',
          'businessName': 'b1',
          'employeeId': 'e1',
          'employeeName': 'e1',
          'employeeEmail': 'e1@email.com',
          'employeeRole': 'e1',
        },
      });
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      await controller.close();

      expect(emitted[0], isEmpty);
      expect(emitted[1].first.employeeName, 'e1');
    });
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

  group('addBusinessEmployee', () {
    const employee = BusinessEmployee(
      relationId: 'r1',
      businessId: 'b1',
      businessName: 'b1',
      businessOwnerId: 'o1',
      employeeId: 'e1',
      employeeName: 'e1',
      employeeEmail: 'e1@email.com',
      employeeRole: 'e1',
    );

    test('calls remote.addBusinessEmployee with existing relationId', () async {
      when(
        () => remote.addBusinessEmployee(any(), any()),
      ).thenAnswer((_) async {});

      await repository.addBusinessEmployee(employee);

      verify(
        () => remote.addBusinessEmployee('r1', employee.toMap()),
      ).called(1);
    });

    test('generates id when relationId is empty', () async {
      const newEmployee = BusinessEmployee(
        relationId: '',
        businessId: 'b1',
        businessName: 'b1',
        businessOwnerId: 'o1',
        employeeId: 'e1',
        employeeName: 'e1',
        employeeEmail: 'e1@email.com',
        employeeRole: 'e1',
      );

      when(
        () => remote.addBusinessEmployee(any(), any()),
      ).thenAnswer((_) async {});

      await repository.addBusinessEmployee(newEmployee);

      verify(
        () => remote.addBusinessEmployee(
          'b1_e1',
          newEmployee.copyWith(relationId: 'b1_e1').toMap(),
        ),
      ).called(1);
    });
  });

  group('removeBusinessEmployee', () {
    const employee = BusinessEmployee(
      relationId: 'r1',
      businessId: 'b1',
      businessName: 'b1',
      businessOwnerId: 'o1',
      employeeId: 'e1',
      employeeName: 'e1',
      employeeEmail: 'e1@email.com',
      employeeRole: 'e1',
    );

    test('delegates to remote.removeBusinessEmployee', () async {
      when(() => remote.removeBusinessEmployee(any())).thenAnswer((_) async {});

      await repository.removeBusinessEmployee(employee);

      verify(
        () => remote.removeBusinessEmployee(employee.relationId),
      ).called(1);
    });
  });

  group('watchEmployedBusinesses', () {
    test('returns empty list when remote emits null', () async {
      when(
        () => remote.watchEmployedBusinesses(any()),
      ).thenAnswer((_) => Stream.value(null));

      final result = await repository.watchEmployedBusinesses(user).first;

      expect(result, isEmpty);
    });

    test('maps remote data to BusinessEmployee list', () async {
      when(() => remote.watchEmployedBusinesses(any())).thenAnswer(
        (_) => Stream.value({
          'r1': {
            'relationId': 'r1',
            'businessId': 'b1',
            'businessName': 'Biz 1',
            'businessOwnerId': 'o1',
            'employeeId': 'u1',
            'employeeName': 'Test User',
            'employeeEmail': 'test@example.com',
            'employeeRole': 'Staff',
          },
        }),
      );

      final result = await repository.watchEmployedBusinesses(user).first;

      expect(result.length, 1);
      expect(result.first.businessName, 'Biz 1');
      expect(result.first.employeeRole, 'Staff');
    });
  });

  group('getBusinessEmployeeByEmail', () {
    test('returns null when remote returns null', () async {
      when(
        () => remote.getBusinessEmployeeByEmail(any(), any()),
      ).thenAnswer((_) async => null);

      final result = await repository.getBusinessEmployeeByEmail(
        'missing@example.com',
        'biz1',
      );

      expect(result, isNull);
    });

    test('returns BusinessEmployee when remote returns valid data', () async {
      when(() => remote.getBusinessEmployeeByEmail(any(), any())).thenAnswer(
        (_) async => {
          'r1': {
            'relationId': 'r1',
            'businessId': 'b1',
            'businessName': 'b1',
            'businessOwnerId': 'o1',
            'employeeId': 'e1',
            'employeeName': 'e1',
            'employeeEmail': 'test@example.com',
            'employeeRole': 'e1',
          },
        },
      );

      final result = await repository.getBusinessEmployeeByEmail(
        'test@example.com',
        'b1',
      );

      expect(result, isNotNull);
      expect(result!.employeeEmail, 'test@example.com');
      expect(result.businessName, 'b1');
    });

    test('calls remote with the correct email and businessId', () async {
      when(
        () => remote.getBusinessEmployeeByEmail(any(), any()),
      ).thenAnswer((_) async => null);

      await repository.getBusinessEmployeeByEmail('hello@example.com', 'b99');

      verify(
        () => remote.getBusinessEmployeeByEmail('hello@example.com', 'b99'),
      ).called(1);
    });
  });
}
