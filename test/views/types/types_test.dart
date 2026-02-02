import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/repositories/abstract_files/type_repository.dart';
import 'package:order_manager/views/types/type_delete_dialog.dart';
import 'package:order_manager/views/types/type_edit_dialog.dart';
import 'package:order_manager/views/types/types.dart';

import '../fake_viewmodel/fake_types_viewmodel.dart';

class MockTypeRepository extends Mock implements TypeRepository {}

class FakeType1 extends Fake implements Type1 {}

Future<void> pumpTypesScreen(
  WidgetTester tester, {
  required List<Type1> types,
}) async {
  final repo = MockTypeRepository();
  when(repo.watchTypes).thenAnswer((_) => Stream.value(types));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [typeRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Types()),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeType1());
  });
  testWidgets('shows loading indicator initially', (tester) async {
    final repo = MockTypeRepository();
    when(repo.watchTypes).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [typeRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Types()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when typesProvider errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typesProvider.overrideWith(
            (ref) => Stream<List<Type1>>.error('error'),
          ),
        ],
        child: const MaterialApp(home: Types()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Error: error'), findsOneWidget);
  });

  testWidgets('shows No Types when list is empty', (tester) async {
    await pumpTypesScreen(tester, types: []);

    expect(find.text('No Types'), findsOneWidget);
  });

  testWidgets('renders list of types', (tester) async {
    await pumpTypesScreen(
      tester,
      types: [
        Type1(id: '1', type: 'Extra', price: 20),
        Type1(id: '2', type: 'Cheese', price: 30),
      ],
    );

    expect(find.text('Type: Extra'), findsOneWidget);
    expect(find.text('Price: 20'), findsOneWidget);
    expect(find.text('Type: Cheese'), findsOneWidget);
    expect(find.text('Price: 30'), findsOneWidget);
  });

  testWidgets('FAB opens add type dialog', (tester) async {
    await pumpTypesScreen(tester, types: []);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(TypeEditDialog), findsOneWidget);
  });

  testWidgets('edit icon opens edit dialog', (tester) async {
    await pumpTypesScreen(
      tester,
      types: [Type1(id: '1', type: 'Extra', price: 20)],
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(TypeEditDialog), findsOneWidget);
    expect(find.text('Extra'), findsOneWidget);
  });

  testWidgets('delete icon opens delete dialog', (tester) async {
    await pumpTypesScreen(
      tester,
      types: [Type1(id: '1', type: 'Extra', price: 20)],
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(TypeDeleteDialog), findsOneWidget);
  });

  testWidgets('confirming delete deletes type and shows snackbar', (
    tester,
  ) async {
    final repo = MockTypeRepository();
    final type = Type1(id: '1', type: 'Extra', price: 20);
    when(repo.watchTypes).thenAnswer((_) => Stream.value([type]));

    final fakeViewModel = FakeTypesViewModel();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typeRepositoryProvider.overrideWithValue(repo),
          typesViewModelProvider.overrideWith(() => fakeViewModel),
        ],
        child: const MaterialApp(home: Types()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(TypeDeleteDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(fakeViewModel.deletedType, type);
    expect(find.text('Type Deleted Successfully'), findsOneWidget);
  });

  testWidgets('saving type saves type and shows snackbar', (tester) async {
    final repo = MockTypeRepository();
    final type = Type1(id: '1', type: 'Extra', price: 20);
    when(repo.watchTypes).thenAnswer((_) => Stream.value([type]));

    final fakeViewModel = FakeTypesViewModel();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typeRepositoryProvider.overrideWithValue(repo),
          typesViewModelProvider.overrideWith(() => fakeViewModel),
        ],
        child: const MaterialApp(home: Types()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(TypeEditDialog), findsOneWidget);
    await tester.tap(find.text('Save Type'));
    await tester.pumpAndSettle();
    expect(fakeViewModel.savedType, type);
    expect(find.text('Type Saved Successfully...'), findsOneWidget);
  });
}
