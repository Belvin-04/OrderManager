import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/views/employees/delete_employee_dialog.dart';

Future<void> pumpEmployeeDeleteDialog(
  WidgetTester tester, {
  required BusinessEmployee initialEmployee,
  required Future<void> Function(BusinessEmployee) onDelete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => EmployeeDeleteDialog(
                    initialEmployee: initialEmployee,
                    onDelete: onDelete,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows delete confirmation dialog', (tester) async {
    const employee = BusinessEmployee(
      relationId: 't1',
      businessId: 't1',
      businessName: 't1',
      employeeId: 't1',
      employeeName: 'Extra',
      employeeEmail: 'extra@email.com',
      employeeRole: 't1',
    );

    await pumpEmployeeDeleteDialog(
      tester,
      initialEmployee: employee,
      onDelete: (_) async {},
    );

    expect(find.text('Delete Employee ?'), findsOneWidget);
    expect(find.text('This action cannot be undone...'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('calls onDelete with the given type', (tester) async {
    BusinessEmployee? deletedEmployee;
    const employee = BusinessEmployee(
      relationId: 't1',
      businessId: 't1',
      businessName: 't1',
      employeeId: 't1',
      employeeName: 'Extra',
      employeeEmail: 'extra@email.com',
      employeeRole: 't1',
    );

    await pumpEmployeeDeleteDialog(
      tester,
      initialEmployee: employee,
      onDelete: (t) async {
        deletedEmployee = t;
      },
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(deletedEmployee, isNotNull);
    expect(deletedEmployee, employee);
  });

  testWidgets('dialog closes after delete', (tester) async {
    const employee = BusinessEmployee(
      relationId: 't1',
      businessId: 't1',
      businessName: 't1',
      employeeId: 't1',
      employeeName: 'Extra',
      employeeEmail: 'extra@email.com',
      employeeRole: 't1',
    );

    await pumpEmployeeDeleteDialog(
      tester,
      initialEmployee: employee,
      onDelete: (_) async {},
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
