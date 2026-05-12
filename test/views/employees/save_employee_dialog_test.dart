import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/providers/app_user_provider.dart';
import 'package:order_manager/views/employees/save_employee_dialog.dart';
import '../../test_helper.dart';

Future<void> pumpSaveEmployeeDialog(
  WidgetTester tester, {
  required BusinessEmployee initialEmployee,
  required Future<void> Function(BusinessEmployee) onSave,
  MockAppUserRepository? repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repo != null) appUserRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
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
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows initial employee name and email', (tester) async {
    const initial = BusinessEmployee(
      relationId: 't1',
      businessId: 't1',
      businessName: 't1',
      employeeId: 't1',
      employeeName: 'Extra',
      employeeEmail: 'extra@email.com',
      employeeRole: 't1',
    );

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (_) async {},
    );

    expect(find.text('Extra'), findsOneWidget);
    expect(find.text("extra@email.com"), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    const initial = BusinessEmployee(
      relationId: 't1',
      businessId: 't1',
      businessName: 't1',
      employeeId: 't1',
      employeeName: '',
      employeeEmail: '',
      employeeRole: 't1',
    );

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
    final repo = MockAppUserRepository();
    when(() => repo.queryByEmail(any())).thenAnswer(
      (_) async =>
          const AppUser(id: 'u1', name: 'User 1', email: 'user1@email.com'),
    );
    when(
      () => repo.watchBusinessEmployees(any()),
    ).thenAnswer((_) => Stream<List<BusinessEmployee>>.value([]));

    BusinessEmployee? savedEmployee;

    const initial = BusinessEmployee(
      relationId: 't1',
      businessId: 't1',
      businessName: 't1',
      employeeId: 't1',
      employeeName: 'Extra',
      employeeEmail: 'extra@email.com',
      employeeRole: 't1',
    );

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (employee) async {
        savedEmployee = employee;
      },
      repo: repo,
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Premium');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'premium@email.com',
    );

    await tester.tap(find.text('Save Employee'));
    await tester.pumpAndSettle();

    expect(savedEmployee, isNotNull);
    expect(savedEmployee!.employeeName, 'Premium');
    expect(savedEmployee!.employeeEmail, "premium@email.com");
  });

  testWidgets('dialog closes after successful save', (tester) async {
    final repo = MockAppUserRepository();
    when(() => repo.queryByEmail(any())).thenAnswer(
      (_) async =>
          const AppUser(id: 'u1', name: 'User 1', email: 'user1@email.com'),
    );
    when(
      () => repo.watchBusinessEmployees(any()),
    ).thenAnswer((_) => Stream<List<BusinessEmployee>>.value([]));
    const initial = BusinessEmployee(
      relationId: 't1',
      businessId: 't1',
      businessName: 't1',
      employeeId: 't1',
      employeeName: 'Extra',
      employeeEmail: 'extra@email.com',
      employeeRole: 't1',
    );

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (_) async {},
      repo: repo,
    );

    await tester.tap(find.text('Save Employee'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("shows error when app user doesn't exist", (tester) async {
    final repo = MockAppUserRepository();
    when(() => repo.queryByEmail(any())).thenAnswer((_) async => null);

    const initial = BusinessEmployee(
      relationId: '',
      businessId: 't1',
      businessName: 't1',
      employeeId: '',
      employeeName: 'New',
      employeeEmail: 'new@email.com',
      employeeRole: '1',
    );

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (_) async {},
      repo: repo,
    );

    await tester.tap(find.text('Save Employee'));
    await tester.pump();

    expect(find.text("User doesn't exist"), findsOneWidget);
  });

  testWidgets('shows error when employee already exists', (tester) async {
    final repo = MockAppUserRepository();
    when(() => repo.queryByEmail(any())).thenAnswer(
      (_) async =>
          const AppUser(id: '1', name: '1', email: 'existing@email.com'),
    );
    when(() => repo.watchBusinessEmployees(any())).thenAnswer(
      (_) => Stream.value([
        const BusinessEmployee(
          relationId: 'r1',
          businessId: 't1',
          businessName: 't1',
          employeeId: 'e1',
          employeeName: 'e1',
          employeeEmail: 'existing@email.com',
          employeeRole: '1',
        ),
      ]),
    );

    const initial = BusinessEmployee(
      relationId: '',
      businessId: 't1',
      businessName: 't1',
      employeeId: '',
      employeeName: 'New',
      employeeEmail: 'existing@email.com',
      employeeRole: '1',
    );

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (_) async {},
      repo: repo,
    );

    await tester.tap(find.text('Save Employee'));
    await tester.pump();

    expect(find.text('Employee already exists'), findsOneWidget);
  });

  testWidgets('shows error when editing email to an existing one', (
    tester,
  ) async {
    final repo = MockAppUserRepository();
    when(() => repo.queryByEmail(any())).thenAnswer(
      (_) async => const AppUser(id: '1', name: '1', email: 'other@email.com'),
    );
    when(() => repo.watchBusinessEmployees(any())).thenAnswer(
      (_) => Stream.value([
        const BusinessEmployee(
          relationId: 'r_existing',
          businessId: 't1',
          businessName: 't1',
          employeeId: 'e_existing',
          employeeName: 'Existing',
          employeeEmail: 'other@email.com',
          employeeRole: '1',
        ),
      ]),
    );

    const initial = BusinessEmployee(
      relationId: 'r_current',
      businessId: 't1',
      businessName: 't1',
      employeeId: 'e_current',
      employeeName: 'Current',
      employeeEmail: 'current@email.com',
      employeeRole: '1',
    );

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (_) async {},
      repo: repo,
    );

    await tester.enterText(find.byType(TextFormField).at(1), 'other@email.com');
    await tester.tap(find.text('Save Employee'));
    await tester.pump();

    expect(find.text('Email already exists'), findsOneWidget);
  });

  testWidgets('allows saving when email is unchanged', (tester) async {
    final repo = MockAppUserRepository();
    when(() => repo.queryByEmail(any())).thenAnswer(
      (_) async =>
          const AppUser(id: '1', name: '1', email: 'current@email.com'),
    );
    when(() => repo.watchBusinessEmployees(any())).thenAnswer(
      (_) => Stream.value([
        const BusinessEmployee(
          relationId: 'r_current',
          businessId: 't1',
          businessName: 't1',
          employeeId: 'e_current',
          employeeName: 'Current',
          employeeEmail: 'current@email.com',
          employeeRole: '1',
        ),
      ]),
    );

    bool onSaveCalled = false;
    const initial = BusinessEmployee(
      relationId: 'r_current',
      businessId: 't1',
      businessName: 't1',
      employeeId: 'e_current',
      employeeName: 'Current',
      employeeEmail: 'current@email.com',
      employeeRole: '1',
    );

    await pumpSaveEmployeeDialog(
      tester,
      initialEmployee: initial,
      onSave: (_) async {
        onSaveCalled = true;
      },
      repo: repo,
    );

    await tester.tap(find.text('Save Employee'));
    await tester.pumpAndSettle();

    expect(onSaveCalled, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
