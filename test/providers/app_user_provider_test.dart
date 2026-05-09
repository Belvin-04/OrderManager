import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/app_user_provider.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/firebase_app_user_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_app_user_remote_data_source.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  setUp(() {
    firestore = FakeFirebaseFirestore();

    container = ProviderContainer(
      overrides: [firebaseFirestoreProvider.overrideWithValue(firestore)],
    );

    addTearDown(container.dispose);
  });

  test(
    'appUserRemoteDataSourceProvider returns FirebaseAppUserRemoteDataSource',
    () {
      final result = container.read(appUserRemoteDataSourceProvider);

      expect(result, isA<FirebaseAppUserRemoteDataSource>());
    },
  );

  test('appUserRemoteDataSourceProvider uses the app_users collection', () {
    final result =
        container.read(appUserRemoteDataSourceProvider)
            as FirebaseAppUserRemoteDataSource;

    expect(result.usersRef.path, 'app_users');
  });

  test('appUserRepositoryProvider returns FirebaseAppUserRepository', () {
    final result = container.read(appUserRepositoryProvider);

    expect(result, isA<FirebaseAppUserRepository>());
  });

  test(
    'appUserRepositoryProvider re-uses the same remote data source instance',
    () {
      final remote = container.read(appUserRemoteDataSourceProvider);
      final repo =
          container.read(appUserRepositoryProvider)
              as FirebaseAppUserRepository;

      expect(repo.remote, same(remote));
    },
  );
}
