import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/business_repository.dart';
import 'package:order_manager/repositories/firebase_business_repository.dart';
import 'package:order_manager/utils/selected_business_notifier.dart';
import 'package:order_manager/viewmodels/business_viewmodel.dart';

class MockBusinessRepository extends Mock implements BusinessRepository {}

void main() {
  late ProviderContainer container;

  late FakeFirebaseFirestore firestore;
  late MockBusinessRepository repo;

  const business = Business(id: 'b1', name: 'Test Business', ownerId: 'owner1');

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = MockBusinessRepository();

    container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(firestore),

        currentUserIdProvider.overrideWith((ref) => 'owner1'),
      ],
    );

    addTearDown(container.dispose);
  });

  test('businessesCollectionProvider returns businesses collection', () {
    final result = container.read(businessesCollectionProvider);

    expect(result.path, 'businesses');
  });

  test('businessRepositoryProvider returns FirebaseBusinessRepository', () {
    final result = container.read(businessRepositoryProvider);

    expect(result, isA<FirebaseBusinessRepository>());
  });

  test('businessRepositoryProvider throws when uid is null', () {
    final testContainer = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(firestore),

        currentUserIdProvider.overrideWith((ref) => null),
      ],
    );

    addTearDown(testContainer.dispose);

    expect(
      () => testContainer.read(businessRepositoryProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception.toString(),
          'message',
          contains('No authenticated user found'),
        ),
      ),
    );
  });

  test('businessesProvider emits businesses from repository', () async {
    when(
      () => repo.watchBusiness(),
    ).thenAnswer((_) => Stream.value([business]));

    final testContainer = ProviderContainer(
      overrides: [businessRepositoryProvider.overrideWithValue(repo)],
    );

    addTearDown(testContainer.dispose);

    final completer = Completer<List<Business>>();

    final sub = testContainer.listen(businessesProvider, (_, next) {
      next.whenData((value) {
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      });
    }, fireImmediately: true);

    addTearDown(sub.close);

    final result = await completer.future;

    expect(result.length, 1);
    expect(result.first.name, 'Test Business');
  });

  test('businessViewModelProvider returns BusinessViewModel', () {
    final result = container.read(businessViewModelProvider.notifier);

    expect(result, isA<BusinessViewModel>());
  });

  test('currentBusinessIdProvider returns selected business id', () {
    final testContainer = ProviderContainer(
      overrides: [
        selectedBusinessProvider.overrideWith(
          () => _FakeSelectedBusinessNotifier(business),
        ),
      ],
    );

    addTearDown(testContainer.dispose);

    final result = testContainer.read(currentBusinessIdProvider);

    expect(result, 'b1');
  });

  test('currentBusinessIdProvider throws when no business selected', () {
    final testContainer = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => 'owner1'),
        selectedBusinessProvider.overrideWith(
          () => _FakeSelectedBusinessNotifier(null),
        ),
      ],
    );

    addTearDown(testContainer.dispose);

    expect(
      () => testContainer.read(currentBusinessIdProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception.toString(),
          'message',
          contains('No business selected'),
        ),
      ),
    );
  });
}

class _FakeSelectedBusinessNotifier extends SelectedBusinessNotifier {
  _FakeSelectedBusinessNotifier(this.business);

  final Business? business;

  @override
  Business? build() {
    return business;
  }
}
