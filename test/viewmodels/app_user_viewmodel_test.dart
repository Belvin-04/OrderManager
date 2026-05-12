import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/providers/app_user_provider.dart';
import 'package:order_manager/providers/employee_provider.dart';
import '../test_helper.dart';

void main() {
  late MockAppUserRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeAppUser());
    registerFallbackValue(FakeBusinessEmployee());
  });

  setUp(() {
    repository = MockAppUserRepository();
    container = ProviderContainer(
      overrides: [appUserRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AppUserViewModel', () {
    test('saveUser calls repository.saveUser', () async {
      const user = AppUser(id: 'u1', email: 'u1@email.com', name: 'u1');
      when(() => repository.saveUser(any())).thenAnswer((_) async {});

      await container.read(employeeViewModelProvider.notifier).saveUser(user);

      verify(() => repository.saveUser(user)).called(1);
    });

    test('addBusinessEmployee calls repository.addBusinessEmployee', () async {
      const employee = BusinessEmployee(
        relationId: 'r1',
        businessId: 'b1',
        businessName: 'b1',
        employeeId: 'e1',
        employeeName: 'e1',
        employeeEmail: 'e1@email.com',
        employeeRole: 'e1',
      );
      when(
        () => repository.addBusinessEmployee(any()),
      ).thenAnswer((_) async {});

      await container
          .read(employeeViewModelProvider.notifier)
          .addBusinessEmployee(employee);

      verify(() => repository.addBusinessEmployee(employee)).called(1);
    });

    test(
      'removeBusinessEmployee calls repository.removeBusinessEmployee',
      () async {
        const employee = BusinessEmployee(
          relationId: 'r1',
          businessId: 'b1',
          businessName: 'b1',
          employeeId: 'e1',
          employeeName: 'e1',
          employeeEmail: 'e1@email.com',
          employeeRole: 'e1',
        );
        when(
          () => repository.removeBusinessEmployee(any()),
        ).thenAnswer((_) async {});

        await container
            .read(employeeViewModelProvider.notifier)
            .removeBusinessEmployee(employee);

        verify(() => repository.removeBusinessEmployee(employee)).called(1);
      },
    );

    test('doesAppUserExists returns true when user is found', () async {
      const email = 'test@email.com';
      when(() => repository.queryByEmail(email)).thenAnswer(
        (_) async => const AppUser(id: '1', email: email, name: '1'),
      );

      final result = await container
          .read(employeeViewModelProvider.notifier)
          .doesAppUserExists(email);

      expect(result, isTrue);
    });

    test('doesAppUserExists returns false when user is not found', () async {
      const email = 'test@email.com';
      when(() => repository.queryByEmail(email)).thenAnswer((_) async => null);

      final result = await container
          .read(employeeViewModelProvider.notifier)
          .doesAppUserExists(email);

      expect(result, isFalse);
    });

    test('doesEmployeeExists returns true when employee is found', () async {
      const email = 'test@email.com';
      const businessId = 'b1';
      when(() => repository.watchBusinessEmployees(businessId)).thenAnswer(
        (_) => Stream.value([
          const BusinessEmployee(
            relationId: 'r1',
            businessId: businessId,
            businessName: 'b1',
            employeeId: 'e1',
            employeeName: 'e1',
            employeeEmail: email,
            employeeRole: 'e1',
          ),
        ]),
      );

      final result = await container
          .read(employeeViewModelProvider.notifier)
          .doesEmployeeExists(email, businessId);

      expect(result, isTrue);
    });

    test(
      '''doesEmployeeExists returns false when employee is not found but other employees exist''',
      () async {
        const email = 'test@email.com';
        const businessId = 'b1';
        when(() => repository.watchBusinessEmployees(businessId)).thenAnswer(
          (_) => Stream.value([
            const BusinessEmployee(
              relationId: 'r1',
              businessId: businessId,
              businessName: 'b1',
              employeeId: 'e1',
              employeeName: 'e1',
              employeeEmail: 'other@email.com',
              employeeRole: 'e1',
            ),
          ]),
        );

        final result = await container
            .read(employeeViewModelProvider.notifier)
            .doesEmployeeExists(email, businessId);

        expect(result, isFalse);
      },
    );

    test(
      'doesEmployeeExists returns false when employee is not found',
      () async {
        const email = 'test@email.com';
        const businessId = 'b1';
        when(
          () => repository.watchBusinessEmployees(businessId),
        ).thenAnswer((_) => Stream.value([]));

        final result = await container
            .read(employeeViewModelProvider.notifier)
            .doesEmployeeExists(email, businessId);

        expect(result, isFalse);
      },
    );

    test('queryBusinessEmployeeByEmail returns employee when found', () async {
      const email = 'test@email.com';
      const businessId = 'b1';
      const employee = BusinessEmployee(
        relationId: 'r1',
        businessId: businessId,
        businessName: 'b1',
        employeeId: 'e1',
        employeeName: 'e1',
        employeeEmail: email,
        employeeRole: 'e1',
      );
      when(
        () => repository.watchBusinessEmployees(businessId),
      ).thenAnswer((_) => Stream.value([employee]));

      final result = await container
          .read(employeeViewModelProvider.notifier)
          .queryBusinessEmployeeByEmail(email, businessId);

      expect(result, employee);
    });

    test(
      '''queryBusinessEmployeeByEmail returns null when not found but other employees exist''',
      () async {
        const email = 'test@email.com';
        const businessId = 'b1';
        const employee = BusinessEmployee(
          relationId: 'r1',
          businessId: businessId,
          businessName: 'b1',
          employeeId: 'e1',
          employeeName: 'e1',
          employeeEmail: 'other@email.com',
          employeeRole: 'e1',
        );
        when(
          () => repository.watchBusinessEmployees(businessId),
        ).thenAnswer((_) => Stream.value([employee]));

        final result = await container
            .read(employeeViewModelProvider.notifier)
            .queryBusinessEmployeeByEmail(email, businessId);

        expect(result, isNull);
      },
    );

    test('queryBusinessEmployeeByEmail returns null when not found', () async {
      const email = 'test@email.com';
      const businessId = 'b1';
      when(
        () => repository.watchBusinessEmployees(businessId),
      ).thenAnswer((_) => Stream.value([]));

      final result = await container
          .read(employeeViewModelProvider.notifier)
          .queryBusinessEmployeeByEmail(email, businessId);

      expect(result, isNull);
    });
  });
}
