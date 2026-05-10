import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/views/employees/delete_employee_dialog.dart';

Future<void> pumpEmployeeDeleteDialog(
  WidgetTester tester, {
  required AppUser initialEmployee,
  required Future<void> Function(AppUser) onDelete,
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
    const employee = AppUser(id: 't1', name: 'Extra', email: "extra@email.com");

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
    AppUser? deletedEmployee;
    const employee = AppUser(id: 't1', name: 'Extra', email: "extra@email.com");

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
    const employee = AppUser(id: 't1', name: 'Extra', email: "extra@email.com");

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
