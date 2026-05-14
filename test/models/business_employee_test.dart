import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/models/business_employee.dart';

void main() {
  group('BusinessEmployee', () {
    const employee = BusinessEmployee(
      relationId: 'rel-1',
      businessId: 'biz-1',
      businessName: 'Test Business',
      employeeId: 'emp-1',
      employeeName: 'John Doe',
      employeeEmail: 'john@test.com',
      employeeRole: 'manager',
    );

    test('fromMap creates object correctly', () {
      final map = {
        'relationId': 'rel-1',
        'businessId': 'biz-1',
        'businessName': 'Test Business',
        'employeeId': 'emp-1',
        'employeeName': 'John Doe',
        'employeeEmail': 'john@test.com',
        'employeeRole': 'manager',
      };

      final result = BusinessEmployee.fromMap(map);

      expect(result, employee);
    });

    test('fromMap returns empty strings for missing fields', () {
      final result = BusinessEmployee.fromMap({});

      expect(result.relationId, '');
      expect(result.businessId, '');
      expect(result.businessName, '');
      expect(result.employeeId, '');
      expect(result.employeeName, '');
      expect(result.employeeEmail, '');
      expect(result.employeeRole, '');
    });

    test('toMap returns correct map', () {
      final result = employee.toMap();

      expect(result, {
        'relationId': 'rel-1',
        'businessId': 'biz-1',
        'businessName': 'Test Business',
        'employeeId': 'emp-1',
        'employeeName': 'John Doe',
        'employeeEmail': 'john@test.com',
        'employeeRole': 'manager',
      });
    });

    test('copyWith updates provided values', () {
      final result = employee.copyWith(
        employeeName: 'Jane Doe',
        employeeRole: 'staff',
      );

      expect(result.relationId, 'rel-1');
      expect(result.businessId, 'biz-1');
      expect(result.businessName, 'Test Business');
      expect(result.employeeId, 'emp-1');
      expect(result.employeeName, 'Jane Doe');
      expect(result.employeeEmail, 'john@test.com');
      expect(result.employeeRole, 'staff');
    });

    test('copyWith keeps old values when null', () {
      final result = employee.copyWith();

      expect(result.relationId, employee.relationId);
      expect(result.businessId, employee.businessId);
      expect(result.businessName, employee.businessName);
      expect(result.employeeId, employee.employeeId);
      expect(result.employeeName, employee.employeeName);
      expect(result.employeeEmail, employee.employeeEmail);
      expect(result.employeeRole, employee.employeeRole);
    });

    test('toBusiness returns Business object', () {
      final business = employee.toBusiness();

      expect(business, isA<Business>());
      expect(business.id, 'biz-1');
      expect(business.name, 'Test Business');
    });

    test('toString returns formatted string', () {
      final result = employee.toString();

      expect(result, contains('BusinessEmployee('));
      expect(result, contains('relationId: rel-1'));
      expect(result, contains('businessId: biz-1'));
      expect(result, contains('businessName: Test Business'));
      expect(result, contains('employeeId: emp-1'));
      expect(result, contains('employeeName: John Doe'));
      expect(result, contains('employeeEmail: john@test.com'));
      expect(result, contains('employeeRole: manager'));
    });

    test('equality operator returns true for equal objects', () {
      const employee2 = BusinessEmployee(
        relationId: 'rel-1',
        businessId: 'biz-1',
        businessName: 'Test Business',
        employeeId: 'emp-1',
        employeeName: 'John Doe',
        employeeEmail: 'john@test.com',
        employeeRole: 'manager',
      );

      final isEqual = employee == employee2;

      expect(isEqual, true);
    });

    test('equality operator returns false for different objects', () {
      const employee2 = BusinessEmployee(
        relationId: 'different',
        businessId: 'biz-1',
        businessName: 'Test Business',
        employeeId: 'emp-1',
        employeeName: 'John Doe',
        employeeEmail: 'john@test.com',
        employeeRole: 'manager',
      );

      final isEqual = employee == employee2;

      expect(isEqual, false);
    });

    test('hashCode returns same value for equal objects', () {
      const employee2 = BusinessEmployee(
        relationId: 'rel-1',
        businessId: 'biz-1',
        businessName: 'Test Business',
        employeeId: 'emp-1',
        employeeName: 'John Doe',
        employeeEmail: 'john@test.com',
        employeeRole: 'manager',
      );

      expect(employee.hashCode, employee2.hashCode);
    });

    test('identical objects return true', () {
      final isEqual = employee == employee;

      expect(isEqual, true);
    });

    test('equality checks relationId', () {
      const other = BusinessEmployee(
        relationId: 'different',
        businessId: 'biz-1',
        businessName: 'Test Business',
        employeeId: 'emp-1',
        employeeName: 'John Doe',
        employeeEmail: 'john@test.com',
        employeeRole: 'manager',
      );

      expect(employee == other, false);
    });

    test('equality checks businessId', () {
      const other = BusinessEmployee(
        relationId: 'rel-1',
        businessId: 'different',
        businessName: 'Test Business',
        employeeId: 'emp-1',
        employeeName: 'John Doe',
        employeeEmail: 'john@test.com',
        employeeRole: 'manager',
      );

      expect(employee == other, false);
    });

    test('equality checks businessName', () {
      const other = BusinessEmployee(
        relationId: 'rel-1',
        businessId: 'biz-1',
        businessName: 'different',
        employeeId: 'emp-1',
        employeeName: 'John Doe',
        employeeEmail: 'john@test.com',
        employeeRole: 'manager',
      );

      expect(employee == other, false);
    });

    test('equality checks employeeId', () {
      const other = BusinessEmployee(
        relationId: 'rel-1',
        businessId: 'biz-1',
        businessName: 'Test Business',
        employeeId: 'different',
        employeeName: 'John Doe',
        employeeEmail: 'john@test.com',
        employeeRole: 'manager',
      );

      expect(employee == other, false);
    });

    test('equality checks employeeName', () {
      const other = BusinessEmployee(
        relationId: 'rel-1',
        businessId: 'biz-1',
        businessName: 'Test Business',
        employeeId: 'emp-1',
        employeeName: 'different',
        employeeEmail: 'john@test.com',
        employeeRole: 'manager',
      );

      expect(employee == other, false);
    });

    test('equality checks employeeEmail', () {
      const other = BusinessEmployee(
        relationId: 'rel-1',
        businessId: 'biz-1',
        businessName: 'Test Business',
        employeeId: 'emp-1',
        employeeName: 'John Doe',
        employeeEmail: 'different@test.com',
        employeeRole: 'manager',
      );

      expect(employee == other, false);
    });

    test('equality checks employeeRole', () {
      const other = BusinessEmployee(
        relationId: 'rel-1',
        businessId: 'biz-1',
        businessName: 'Test Business',
        employeeId: 'emp-1',
        employeeName: 'John Doe',
        employeeEmail: 'john@test.com',
        employeeRole: 'different',
      );

      expect(employee == other, false);
    });
  });
}
