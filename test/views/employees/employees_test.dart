import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/providers/app_user_provider.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/employee_provider.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/app_user_repository.dart';
import 'package:order_manager/views/employees/delete_employee_dialog.dart';
import 'package:order_manager/views/employees/employees.dart';
import 'package:order_manager/views/employees/save_employee_dialog.dart';
import '../../test_helper.dart';

class MockUser extends Mock implements User {
  @override
  String get uid => 'uid123';
}

Future<void> pumpEmployeesScreen(
  WidgetTester tester, {
  AppUserRepository? repo,
  AsyncValue<List<BusinessEmployee>>? employeesState,
}) async {
  const business = Business(id: "1", name: "Business 1", ownerId: "uid123");
  final mockUser = MockUser();

  final container = ProviderContainer(
    overrides: [
      if (repo != null) appUserRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWithValue(mockUser),
      if (employeesState != null)
        employeesProvider(business.id).overrideWithValue(employeesState),
    ],
  );

  container.read(selectedBusinessProvider.notifier).state = business;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Employees()),
    ),
  );
}

void main() {
  setUp(() {
    registerFallbackValue(MockBusinessEmployee());
  });

  testWidgets('shows loading indicator initially', (tester) async {
    await pumpEmployeesScreen(
      tester,
      employeesState: const AsyncValue.loading(),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when employeesProvider errors', (
    tester,
  ) async {
    await pumpEmployeesScreen(
      tester,
      employeesState: AsyncValue.error("error", StackTrace.current),
    );

    await tester.pump();

    expect(find.text('Error: error'), findsOneWidget);
  });

  testWidgets('shows No Employees when list is empty', (tester) async {
    final repo = MockAppUserRepository();
    when(
      () => repo.watchBusinessEmployees(any()),
    ).thenAnswer((_) => Stream.value([]));
    await pumpEmployeesScreen(tester, repo: repo);
    await tester.pumpAndSettle();
    expect(find.text('No Employees'), findsOneWidget);
  });

  testWidgets('renders list of employees', (tester) async {
    final repo = MockAppUserRepository();
    when(() => repo.watchBusinessEmployees(any())).thenAnswer(
      (_) => Stream.value([
        const BusinessEmployee(
          relationId: '1',
          businessId: '1',
          businessName: '1',
          employeeId: '1',
          employeeName: 'Employee 1',
          employeeEmail: '1@email.com',
          employeeRole: '1',
        ),
        const BusinessEmployee(
          relationId: '2',
          businessId: '1',
          businessName: '1',
          employeeId: '2',
          employeeName: 'Employee 2',
          employeeEmail: '2@email.com',
          employeeRole: '2',
        ),
      ]),
    );
    await pumpEmployeesScreen(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.textContaining('Employee 1'), findsOneWidget);
    expect(find.textContaining('1@email.com'), findsOneWidget);
    expect(find.textContaining('Employee 2'), findsOneWidget);
    expect(find.textContaining('2@email.com'), findsOneWidget);
  });

  testWidgets('FAB opens add employee dialog', (tester) async {
    final repo = MockAppUserRepository();
    when(
      () => repo.watchBusinessEmployees(any()),
    ).thenAnswer((_) => Stream.value([]));
    await pumpEmployeesScreen(tester, repo: repo);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(SaveEmployeeDialog), findsOneWidget);
  });

  testWidgets('edit icon opens edit dialog', (tester) async {
    final repo = MockAppUserRepository();
    when(() => repo.watchBusinessEmployees(any())).thenAnswer(
      (_) => Stream.value([
        const BusinessEmployee(
          relationId: '1',
          businessId: '1',
          businessName: '1',
          employeeId: '1',
          employeeName: 'Employee 1',
          employeeEmail: '1@email.com',
          employeeRole: '1',
        ),
      ]),
    );
    await pumpEmployeesScreen(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(SaveEmployeeDialog), findsOneWidget);
    expect(find.text('Employee 1'), findsOneWidget);
    expect(find.text('1@email.com'), findsOneWidget);
  });

  testWidgets('delete icon opens delete dialog', (tester) async {
    final repo = MockAppUserRepository();
    when(() => repo.watchBusinessEmployees(any())).thenAnswer(
      (_) => Stream.value([
        const BusinessEmployee(
          relationId: '1',
          businessId: '1',
          businessName: '1',
          employeeId: '1',
          employeeName: 'Employee 1',
          employeeEmail: '1@email.com',
          employeeRole: '1',
        ),
      ]),
    );

    await pumpEmployeesScreen(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(EmployeeDeleteDialog), findsOneWidget);
  });

  testWidgets('confirming delete deletes employee and shows snackbar', (
    tester,
  ) async {
    final repo = MockAppUserRepository();
    const employee = BusinessEmployee(
      relationId: '1',
      businessId: '1',
      businessName: '1',
      employeeId: '1',
      employeeName: 'Employee 1',
      employeeEmail: '1@email.com',
      employeeRole: '1',
    );
    when(
      () => repo.watchBusinessEmployees(any()),
    ).thenAnswer((_) => Stream.value([employee]));

    when(() => repo.removeBusinessEmployee(any())).thenAnswer((_) async {});

    await pumpEmployeesScreen(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(EmployeeDeleteDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    verify(() => repo.watchBusinessEmployees(any())).called(1);
    verify(() => repo.removeBusinessEmployee(any())).called(1);
    expect(find.text('Employee Deleted Successfully'), findsOneWidget);
  });

  testWidgets('saving employee saves employee and shows snackbar', (
    tester,
  ) async {
    final repo = MockAppUserRepository();
    const employee = BusinessEmployee(
      relationId: '1',
      businessId: '1',
      businessName: '1',
      employeeId: '1',
      employeeName: 'Employee 1',
      employeeEmail: '1@email.com',
      employeeRole: '1',
    );
    when(
      () => repo.watchBusinessEmployees(any()),
    ).thenAnswer((_) => Stream.value([employee]));
    when(() => repo.addBusinessEmployee(any())).thenAnswer((_) async {});
    when(() => repo.queryByEmail(any())).thenAnswer(
      (_) async => const AppUser(id: '1', name: '1', email: '1@email.com'),
    );

    await pumpEmployeesScreen(tester, repo: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, "Employee 2");
    await tester.enterText(find.byType(TextFormField).last, "2@email.com");

    expect(find.byType(SaveEmployeeDialog), findsOneWidget);
    await tester.tap(find.text('Save Employee'));
    await tester.pumpAndSettle();
    verify(() => repo.watchBusinessEmployees(any())).called(2);
    verify(() => repo.addBusinessEmployee(any())).called(1);
    verify(() => repo.queryByEmail(any())).called(1);
    expect(find.text('Employee Saved Successfully...'), findsOneWidget);
  });
}
