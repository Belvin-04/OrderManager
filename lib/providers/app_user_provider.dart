import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/app_user_repository.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/app_user_remote_data_source.dart';
import 'package:order_manager/repositories/firebase_app_user_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_app_user_remote_data_source.dart';

final appUserRemoteDataSourceProvider = Provider<AppUserRemoteDataSource>((
  ref,
) {
  return FirebaseAppUserRemoteDataSource(
    ref.watch(firebaseFirestoreProvider).collection('app_users'),
    ref.watch(firebaseFirestoreProvider).collection('business_employees'),
  );
});

final appUserRepositoryProvider = Provider<AppUserRepository>((ref) {
  return FirebaseAppUserRepository(ref.watch(appUserRemoteDataSourceProvider));
});
