import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/views/employees/save_employee_dialog.dart';

Future<void> pumpSaveEmployeeDialog(
  WidgetTester tester, {
  required AppUser initialEmployee,
  required Future<void> Function(AppUser) onSave,
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
                  builder: (_) => SaveEmployeeDialog(
                    initialEmployee: initialEmployee,
                    onSave: onSave,
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
  testWidgets('shows initial employee name and email', (tester) async {
    const initial = AppUser(id: 't1', name: 'Extra', email: "extra@email.com");

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (_) async {},
    );

    expect(find.text('Extra'), findsOneWidget);
    expect(find.text("extra@email.com"), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    const initial = AppUser(id: 't1', name: '', email: "");

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (_) async {},
    );

    await tester.tap(find.text('Save Employee'));
    await tester.pump();

    expect(find.text('Please Enter Employee Name'), findsOneWidget);
    expect(find.text('Please Enter Employee Email'), findsOneWidget);
  });

  testWidgets('calls onSave with updated employee when form is valid', (
    tester,
  ) async {
    AppUser? savedEmployee;

    const initial = AppUser(id: 't1', name: 'Extra', email: "extra@email.com");

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (employee) async {
        savedEmployee = employee;
      },
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Premium');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'premium@email.com',
    );

    await tester.tap(find.text('Save Employee'));
    await tester.pumpAndSettle();

    expect(savedEmployee, isNotNull);
    expect(savedEmployee!.name, 'Premium');
    expect(savedEmployee!.email, "premium@email.com");
  });

  testWidgets('dialog closes after successful save', (tester) async {
    const initial = AppUser(id: 't1', name: 'Extra', email: "extra@email.com");

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (_) async {},
    );

    await tester.tap(find.text('Save Employee'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
