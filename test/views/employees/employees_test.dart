import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/providers/app_user_provider.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/employee_provider.dart';
import 'package:order_manager/repositories/abstract_files/app_user_repository.dart';
import 'package:order_manager/views/employees/delete_employee_dialog.dart';
import 'package:order_manager/views/employees/employees.dart';
import 'package:order_manager/views/employees/save_employee_dialog.dart';

class MockAppUserRepository extends Mock implements AppUserRepository {}

class MockAppUser extends Mock implements AppUser {}

Future<void> pumpEmployeesScreen(
  WidgetTester tester, {
  required List<AppUser> employees,
}) async {
  final repo = MockAppUserRepository();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appUserRepositoryProvider.overrideWithValue(repo),
        currentBusinessIdProvider.overrideWithValue("1"),
        employeesProvider("1").overrideWithValue(AsyncValue.data(employees)),
      ],
      child: const MaterialApp(home: Employees()),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockAppUser());
  });

  testWidgets('shows loading indicator initially', (tester) async {
    final repo = MockAppUserRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUserRepositoryProvider.overrideWithValue(repo),
          currentBusinessIdProvider.overrideWithValue("1"),
          employeesProvider("1").overrideWithValue(const AsyncValue.loading()),
        ],
        child: const MaterialApp(home: Employees()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when employeesProvider errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUserRepositoryProvider.overrideWithValue(MockAppUserRepository()),
          currentBusinessIdProvider.overrideWithValue("1"),
          employeesProvider(
            "1",
          ).overrideWithValue(AsyncValue.error("error", StackTrace.current)),
        ],
        child: const MaterialApp(home: Employees()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Error: error'), findsOneWidget);
  });

  testWidgets('shows No Employees when list is empty', (tester) async {
    await pumpEmployeesScreen(tester, employees: []);

    expect(find.text('No Employees'), findsOneWidget);
  });

  testWidgets('renders list of employees', (tester) async {
    await pumpEmployeesScreen(
      tester,
      employees: [
        const AppUser(id: '1', name: 'Employee 1', email: '1@email.com'),
        const AppUser(id: '2', name: 'Employee 2', email: '2@email.com'),
      ],
    );

    expect(find.textContaining('Employee 1'), findsOneWidget);
    expect(find.textContaining('1@email.com'), findsOneWidget);
    expect(find.textContaining('Employee 2'), findsOneWidget);
    expect(find.textContaining('2@email.com'), findsOneWidget);
  });

  testWidgets('FAB opens add employee dialog', (tester) async {
    await pumpEmployeesScreen(tester, employees: []);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(SaveEmployeeDialog), findsOneWidget);
  });

  testWidgets('edit icon opens edit dialog', (tester) async {
    await pumpEmployeesScreen(
      tester,
      employees: [
        const AppUser(id: '1', name: 'Employee 1', email: '1@email.com'),
      ],
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(SaveEmployeeDialog), findsOneWidget);
    expect(find.text('Employee 1'), findsOneWidget);
    expect(find.text('1@email.com'), findsOneWidget);
  });

  testWidgets('delete icon opens delete dialog', (tester) async {
    await pumpEmployeesScreen(
      tester,
      employees: [
        const AppUser(id: '1', name: 'Employee 1', email: '1@email.com'),
      ],
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(EmployeeDeleteDialog), findsOneWidget);
  });

  testWidgets('confirming delete deletes employee and shows snackbar', (
    tester,
  ) async {
    final repo = MockAppUserRepository();
    const employee = AppUser(id: '1', name: 'Employee 1', email: '1@email.com');
    when(
      () => repo.watchBusinessUsers(any()),
    ).thenAnswer((_) => Stream.value([employee]));
    when(() => repo.deleteUser(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUserRepositoryProvider.overrideWithValue(repo),
          currentBusinessIdProvider.overrideWithValue("1"),
          employeesProvider(
            "1",
          ).overrideWithValue(const AsyncValue.data([employee])),
        ],
        child: const MaterialApp(home: Employees()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(EmployeeDeleteDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    verify(() => repo.deleteUser(any())).called(1);
    expect(find.text('Employee Deleted Successfully'), findsOneWidget);
  }, skip: true);

  testWidgets('saving employee saves employee and shows snackbar', (
    tester,
  ) async {
    final repo = MockAppUserRepository();
    const employee = AppUser(id: '1', name: 'Employee 1', email: '1@email.com');
    when(
      () => repo.watchBusinessUsers(any()),
    ).thenAnswer((_) => Stream.value([employee]));
    when(() => repo.saveUser(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appUserRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Employees()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(SaveEmployeeDialog), findsOneWidget);
    await tester.tap(find.text('Save Employee'));
    await tester.pumpAndSettle();
    verify(() => repo.saveUser(any())).called(1);
    expect(find.text('Employee Saved Successfully...'), findsOneWidget);
  }, skip: true);
}
