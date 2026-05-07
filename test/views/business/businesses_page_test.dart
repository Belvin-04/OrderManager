import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/business_repository.dart';
import 'package:order_manager/views/business/add_business_dialog.dart';
import 'package:order_manager/views/business/businesses_page.dart';
import 'package:order_manager/views/business/delete_business_dialog.dart';
import 'package:order_manager/views/startup/preferred_startup_screen.dart';

class MockAuthRepository extends Mock implements FirebaseAuth {}

class MockBusinessRepository extends Mock implements BusinessRepository {}

class FakeBusiness extends Mock implements Business {}

Future<ProviderContainer> pumpBusinessScreen(
  WidgetTester tester, {
  required AsyncValue<List<Business>> businessesState,
  Business? selectedBusiness,
}) async {
  final businessRepo = MockBusinessRepository();
  final authRepo = MockAuthRepository();

  when(
    () => businessRepo.saveBusiness(any()),
  ).thenAnswer((i) async => i.positionalArguments.first as Business);

  when(() => businessRepo.deleteBusiness(any())).thenAnswer((_) async {});

  when(
    () => businessRepo.deleteBusinessCollections(any()),
  ).thenAnswer((_) async {});
  final container = ProviderContainer(
    retry: (_, __) => null,
    overrides: [
      businessesProvider.overrideWithValue(businessesState),
      firebaseAuthProvider.overrideWithValue(authRepo),
      businessRepositoryProvider.overrideWithValue(businessRepo),
    ],
  );

  if (selectedBusiness != null) {
    container.read(selectedBusinessProvider.notifier).selectedBusiness =
        selectedBusiness;
  }

  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: BusinessGate()),
    ),
  );

  return container;
}

void main() {
  const business = Business(id: 'b1', name: 'Test Business');

  setUp(() {
    registerFallbackValue(FakeBusiness());
  });

  testWidgets('shows BusinessesPage when no selected business', (tester) async {
    await pumpBusinessScreen(tester, businessesState: const AsyncData([]));

    expect(find.text('Businesses'), findsOneWidget);
  });

  testWidgets('shows PreferredStartupScreen when business selected', (
    tester,
  ) async {
    await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([]),
      selectedBusiness: business,
    );

    expect(find.byType(PreferredStartupScreen), findsOneWidget);
  });

  testWidgets('shows loading indicator while businesses load', (tester) async {
    await pumpBusinessScreen(tester, businessesState: const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error text when businesses fail', (tester) async {
    await pumpBusinessScreen(
      tester,
      businessesState: AsyncError('boom', StackTrace.current),
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows empty state message', (tester) async {
    await pumpBusinessScreen(tester, businessesState: const AsyncData([]));

    expect(find.textContaining('No businesses found'), findsOneWidget);
  });

  testWidgets('renders business list', (tester) async {
    await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([business]),
    );

    expect(find.text('Test Business'), findsOneWidget);

    expect(find.byIcon(Icons.store), findsOneWidget);

    expect(find.byTooltip('Edit Business'), findsOneWidget);

    expect(find.byTooltip('Delete Business'), findsOneWidget);
  });

  testWidgets('renders divider between businesses', (tester) async {
    await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([
        Business(id: '1', name: 'One'),
        Business(id: '2', name: 'Two'),
      ]),
    );

    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('tapping business selects business', (tester) async {
    final container = await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([business]),
    );

    await tester.tap(find.text('Test Business'));

    await tester.pump();

    expect(container.read(selectedBusinessProvider), business);
  });

  testWidgets('tapping Create Business shows AddBusinessDialog', (
    tester,
  ) async {
    await pumpBusinessScreen(tester, businessesState: const AsyncData([]));

    await tester.pump();

    await tester.tap(find.byTooltip('Create Business'));

    await tester.pump();

    expect(find.byType(AddBusinessDialog), findsOneWidget);
  });

  testWidgets(
    'tapping Edit Business shows AddBusinessDialog with existing business',
    (tester) async {
      await pumpBusinessScreen(
        tester,
        businessesState: const AsyncData([business]),
      );

      await tester.tap(find.byTooltip('Edit Business'));

      await tester.pump();

      expect(find.byType(AddBusinessDialog), findsOneWidget);

      expect(find.text('Test Business'), findsWidgets);
    },
  );

  testWidgets('tapping Delete Business shows DeleteBusinessDialog', (
    tester,
  ) async {
    await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([business]),
    );

    await tester.tap(find.byTooltip('Delete Business'));

    await tester.pump();

    expect(find.byType(DeleteBusinessDialog), findsOneWidget);
  });

  testWidgets('tapping Logout clears selected business and signs out', (
    tester,
  ) async {
    final result = await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([business]),
    );

    await tester.pump();

    await tester.tap(find.byTooltip('Logout'));

    await tester.pump();

    expect(result.read(selectedBusinessProvider), isNull);

    verify(result.read(firebaseAuthProvider).signOut).called(1);
  });

  testWidgets('saving business shows success snackbar', (tester) async {
    await pumpBusinessScreen(tester, businessesState: const AsyncData([]));

    await tester.pump();

    await tester.tap(find.byTooltip('Create Business'));

    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'New Business');

    await tester.tap(find.text('Save'));

    await tester.pump();

    expect(find.text('Business saved successfully.'), findsOneWidget);
  });

  testWidgets('save failure shows error snackbar', (tester) async {
    final container = await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([]),
    );

    final repo =
        container.read(businessRepositoryProvider) as MockBusinessRepository;

    when(() => repo.saveBusiness(any())).thenThrow(Exception());

    await tester.pump();

    await tester.tap(find.byTooltip('Create Business'));

    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'New Business');

    await tester.tap(find.text('Save'));

    await tester.pump();

    expect(find.text('Unable to save business.'), findsOneWidget);
  });

  testWidgets('delete success shows snackbar', (tester) async {
    await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([business]),
    );

    await tester.tap(find.byTooltip('Delete Business'));

    await tester.pump();

    await tester.tap(find.text('Delete'));

    await tester.pump();

    expect(find.text('Business deleted successfully.'), findsOneWidget);
  });

  testWidgets('delete failure shows snackbar', (tester) async {
    final container = await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([business]),
    );

    final repo =
        container.read(businessRepositoryProvider) as MockBusinessRepository;

    when(() => repo.deleteBusinessCollections(any())).thenThrow(Exception());

    await tester.tap(find.byTooltip('Delete Business'));

    await tester.pump();

    await tester.tap(find.text('Delete'));

    await tester.pump();

    expect(find.text('Unable to delete business.'), findsOneWidget);
  });

  testWidgets('tapping business redirects to PreferredStartupScreen', (
    tester,
  ) async {
    await pumpBusinessScreen(
      tester,
      businessesState: const AsyncData([business]),
    );

    expect(find.byType(PreferredStartupScreen), findsNothing);

    await tester.tap(find.text('Test Business'));

    await tester.pump();

    expect(find.byType(PreferredStartupScreen), findsOneWidget);
  });

  testWidgets('saving a new business redirects to PreferredStartupScreen', (
    tester,
  ) async {
    await pumpBusinessScreen(tester, businessesState: const AsyncData([]));

    expect(find.byType(PreferredStartupScreen), findsNothing);

    await tester.pump();

    await tester.tap(find.byTooltip('Create Business'));

    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'New Business');

    await tester.tap(find.text('Save'));

    await tester.pump();

    expect(find.byType(PreferredStartupScreen), findsOneWidget);
  });
}
