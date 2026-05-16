import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/employee_provider.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('isEmployeeProvider', () {
    test('returns false if selectedBusiness is null', () {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWith((ref) => 'user-1')],
      );
      addTearDown(container.dispose);

      expect(container.read(isEmployeeProvider), false);
    });

    test('returns false if currentUserId is null', () async {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWith((ref) => null)],
      );
      addTearDown(container.dispose);

      await container
          .read(selectedBusinessProvider.notifier)
          .setSelectedBusiness(
            const Business(id: 'b1', name: 'Biz', ownerId: 'owner-1'),
          );

      expect(container.read(isEmployeeProvider), false);
    });

    test('returns false if currentUserId is the ownerId', () async {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWith((ref) => 'user-1')],
      );
      addTearDown(container.dispose);

      await container
          .read(selectedBusinessProvider.notifier)
          .setSelectedBusiness(
            const Business(id: 'b1', name: 'Biz', ownerId: 'user-1'),
          );

      expect(container.read(isEmployeeProvider), false);
    });

    test('returns true if currentUserId is NOT the ownerId', () async {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWith((ref) => 'user-1')],
      );
      addTearDown(container.dispose);

      await container
          .read(selectedBusinessProvider.notifier)
          .setSelectedBusiness(
            const Business(id: 'b1', name: 'Biz', ownerId: 'owner-1'),
          );

      expect(container.read(isEmployeeProvider), true);
    });
  });

  group('employeesProvider', () {
    test('emits list of employees from firestore', () async {
      final firestore = FakeFirebaseFirestore();
      const businessId = 'b1';
      const employee = BusinessEmployee(
        relationId: 'r1',
        businessId: businessId,
        businessName: 'b1',
        businessOwnerId: 'o1',
        employeeId: 'e1',
        employeeName: 'e1',
        employeeEmail: 'e1@email.com',
        employeeRole: 'e1',
      );

      await firestore.collection('business_employees').add(employee.toMap());

      final container = ProviderContainer(
        overrides: [firebaseFirestoreProvider.overrideWithValue(firestore)],
      );
      addTearDown(container.dispose);

      final completer = Completer<List<BusinessEmployee>>();

      final sub = container.listen(employeesProvider(businessId), (_, next) {
        if (next is AsyncData<List<BusinessEmployee>>) {
          if (!completer.isCompleted) completer.complete(next.value);
        }
      });

      final result = await completer.future.timeout(const Duration(seconds: 5));

      expect(result.length, 1);
      expect(result[0].businessId, businessId);
      sub.close();
    });
  });
}
