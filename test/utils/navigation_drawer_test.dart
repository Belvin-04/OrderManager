import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/utils/change_theme_switch.dart';
import 'package:order_manager/utils/navigation_drawer.dart' as drawer;
import 'package:order_manager/views/employees/employees.dart';
import 'package:order_manager/views/items/items.dart';
import 'package:order_manager/views/quick_orders.dart';
import 'package:order_manager/views/tables/tables.dart';
import 'package:order_manager/views/types/types.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helper.dart';

Future<
  ({
    ProviderContainer container,
    MockBusinessRepository businessRepo,
    MockAuthRepository authRepo,
  })
>
pumpDrawer(WidgetTester tester, {Business? selectedBusiness}) async {
  final businessRepo = MockBusinessRepository();
  final authRepo = MockAuthRepository();

  when(authRepo.signOut).thenAnswer((_) async {});

  final container = ProviderContainer(
    retry: (_, __) => null,
    overrides: [
      businessRepositoryProvider.overrideWithValue(businessRepo),
      firebaseAuthProvider.overrideWithValue(authRepo),
      currentBusinessIdProvider.overrideWithValue(selectedBusiness?.id ?? ""),
    ],
  );

  if (selectedBusiness != null) {
    await container
        .read(selectedBusinessProvider.notifier)
        .setSelectedBusiness(selectedBusiness);
  }

  addTearDown(() async {
    container.dispose();

    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pump();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          drawer: const drawer.NavigationDrawer(),
          body: const Center(child: Text('Home')),
        ),
      ),
    ),
  );

  await tester.tap(find.byTooltip('Open navigation menu'));

  await tester.pump();

  await tester.pump(const Duration(milliseconds: 350));

  return (container: container, businessRepo: businessRepo, authRepo: authRepo);
}

Future<void> tapDrawerItem(WidgetTester tester, String text) async {
  final finder = find.text(text);

  expect(finder, findsOneWidget);

  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).first,
  );

  await tester.tap(finder);

  await tester.pump();

  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() {
    registerFallbackValue(FakeBusiness());
  });

  const business = Business(id: 'b1', name: 'Test Business', ownerId: 'owner1');

  testWidgets('navigation drawer shows all menu items', (tester) async {
    await pumpDrawer(tester, selectedBusiness: business);

    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Tables'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('Quick Orders'), findsOneWidget);
    expect(find.text('Manage Employees'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.text('Switch Business'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Dark Theme'), 300);
    await tester.pumpAndSettle();

    expect(find.text('Dark Theme'), findsOneWidget);
  });

  testWidgets('shows selected business name', (tester) async {
    await pumpDrawer(tester, selectedBusiness: business);

    expect(find.text('Test Business'), findsOneWidget);
  });

  testWidgets('shows fallback text when no business selected', (tester) async {
    await pumpDrawer(tester);

    expect(find.text('Not selected'), findsOneWidget);
  });

  testWidgets('tapping Items navigates to Items screen', (tester) async {
    await pumpDrawer(tester);

    await tapDrawerItem(tester, 'Items');

    expect(find.byType(Items), findsOneWidget);
  });

  testWidgets('tapping Tables navigates to Tables screen', (tester) async {
    await pumpDrawer(tester);

    await tapDrawerItem(tester, 'Tables');

    expect(find.byType(Tables), findsOneWidget);
  });

  testWidgets('tapping Types navigates to Types screen', (tester) async {
    await pumpDrawer(tester);

    await tapDrawerItem(tester, 'Types');

    expect(find.byType(Types), findsOneWidget);
  });

  testWidgets('tapping Quick Orders navigates to Quick Orders screen', (
    tester,
  ) async {
    await pumpDrawer(tester);

    await tapDrawerItem(tester, 'Quick Orders');

    expect(find.byType(QuickOrders), findsOneWidget);
  });

  testWidgets('tapping Manage Employees navigates to Manage Employees screen', (
    tester,
  ) async {
    await pumpDrawer(tester, selectedBusiness: business);

    await tapDrawerItem(tester, 'Manage Employees');

    expect(find.byType(Employees), findsOneWidget);
  });

  testWidgets('dark theme switch is shown', (tester) async {
    await pumpDrawer(tester);
    await tester.scrollUntilVisible(find.text('Dark Theme'), 300);
    await tester.pumpAndSettle();

    expect(find.byType(ChangeThemeSwitch), findsOneWidget);
  });

  testWidgets('tapping Switch Business clears selected business', (
    tester,
  ) async {
    final result = await pumpDrawer(tester, selectedBusiness: business);

    expect(result.container.read(selectedBusinessProvider), isNotNull);

    await tapDrawerItem(tester, 'Switch Business');

    expect(result.container.read(selectedBusinessProvider), isNull);
  });

  testWidgets('tapping Logout clears business and signs out', (tester) async {
    final result = await pumpDrawer(tester, selectedBusiness: business);

    await tapDrawerItem(tester, 'Logout');

    expect(result.container.read(selectedBusinessProvider), isNull);

    verify(result.authRepo.signOut).called(1);
  });

  testWidgets('navigation drawer hides Manage Employees for employee', (
    tester,
  ) async {
    const business = Business(
      id: 'b1',
      name: 'Test Business',
      ownerId: 'owner1',
    );

    final container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => 'employee1')],
    );
    addTearDown(container.dispose);

    await container
        .read(selectedBusinessProvider.notifier)
        .setSelectedBusiness(business);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(),
            drawer: const drawer.NavigationDrawer(),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Manage Employees'), findsNothing);
  });
}
