import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/business_repository.dart';

class MockBusinessRepository extends Mock implements BusinessRepository {}

class FakeBusiness extends Fake implements Business {}

void main() {
  late ProviderContainer container;
  late MockBusinessRepository repo;

  const business = Business(id: 'b1', name: 'Test Business');

  setUpAll(() {
    registerFallbackValue(FakeBusiness());
  });

  setUp(() {
    repo = MockBusinessRepository();

    container = ProviderContainer(
      overrides: [
        businessRepositoryProvider.overrideWithValue(repo),

        currentUserIdProvider.overrideWith((ref) => 'user_1'),
      ],
    );

    addTearDown(container.dispose);
  });

  test('saveBusiness saves business with current ownerId', () async {
    when(
      () => repo.saveBusiness(any()),
    ).thenAnswer((_) async => business.copyWith(ownerId: 'user_1'));

    final notifier = container.read(businessViewModelProvider.notifier);

    await notifier.saveBusiness(business);

    final captured =
        verify(() => repo.saveBusiness(captureAny())).captured.single
            as Business;

    expect(captured.ownerId, 'user_1');
  });

  test('saveBusiness updates selected business', () async {
    when(
      () => repo.saveBusiness(any()),
    ).thenAnswer((_) async => business.copyWith(ownerId: 'user_1'));

    final notifier = container.read(businessViewModelProvider.notifier);

    await notifier.saveBusiness(business);

    final selected = container.read(selectedBusinessProvider);

    expect(selected?.id, 'b1');
    expect(selected?.ownerId, 'user_1');
  });

  test('deleteBusiness deletes collections and business', () async {
    when(() => repo.deleteBusinessCollections(any())).thenAnswer((_) async {});

    when(() => repo.deleteBusiness(any())).thenAnswer((_) async {});

    final notifier = container.read(businessViewModelProvider.notifier);

    await notifier.deleteBusiness(business);

    verify(() => repo.deleteBusinessCollections('b1')).called(1);

    verify(() => repo.deleteBusiness(business)).called(1);
  });

  test(
    'deleteBusiness clears selected business when selected matches',
    () async {
      when(
        () => repo.deleteBusinessCollections(any()),
      ).thenAnswer((_) async {});

      when(() => repo.deleteBusiness(any())).thenAnswer((_) async {});

      container.read(selectedBusinessProvider.notifier).selectedBusiness =
          business;

      final notifier = container.read(businessViewModelProvider.notifier);

      await notifier.deleteBusiness(business);

      final selected = container.read(selectedBusinessProvider);

      expect(selected, isNull);
    },
  );

  test('clearSelectedBusiness clears selected business', () async {
    container.read(selectedBusinessProvider.notifier).selectedBusiness =
        business;

    final notifier = container.read(businessViewModelProvider.notifier);

    notifier.clearSelectedBusiness();

    final selected = container.read(selectedBusinessProvider);

    expect(selected, isNull);
  });

  test('_deleteBusinessCollections sets loading and data state', () async {
    when(() => repo.deleteBusiness(any())).thenAnswer((_) async {});
    when(() => repo.deleteBusinessCollections(any())).thenAnswer((_) async {});

    final notifier = container.read(businessViewModelProvider.notifier);

    final future = notifier.deleteBusiness(business);

    expect(
      container.read(businessViewModelProvider),
      const AsyncLoading<void>(),
    );

    await future;

    expect(
      container.read(businessViewModelProvider),
      const AsyncData<void>(null),
    );
  });

  test('_deleteBusinessCollections throws on failure', () async {
    when(() => repo.deleteBusiness(any())).thenAnswer((_) async {});

    when(
      () => repo.deleteBusinessCollections(any()),
    ).thenThrow(Exception('boom'));

    final notifier = container.read(businessViewModelProvider.notifier);

    await expectLater(
      notifier.deleteBusiness(business),
      throwsA(isA<Exception>()),
    );

    verify(() => repo.deleteBusinessCollections('b1')).called(1);

    verifyNever(() => repo.deleteBusiness(any()));
  });
}
