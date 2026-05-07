import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/business_repository.dart';
import 'package:order_manager/repositories/firebase_business_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_business_remote_data_source.dart';
import 'package:order_manager/utils/selected_business_notifier.dart';
import 'package:order_manager/viewmodels/business_viewmodel.dart';

final selectedBusinessProvider =
    NotifierProvider<SelectedBusinessNotifier, Business?>(
      SelectedBusinessNotifier.new,
    );

final businessesCollectionProvider =
    Provider<CollectionReference<Map<String, dynamic>>>((ref) {
      return ref.watch(firebaseFirestoreProvider).collection('businesses');
    });

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  final userBusinessCollection = ref.watch(businessesCollectionProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    throw StateError('No authenticated user found.');
  }
  final remote = FirebaseBusinessRemoteDataSource(
    userBusinessCollection,
    ownerId: uid,
    firestore: ref.watch(firebaseFirestoreProvider),
  );
  return FirebaseBusinessRepository(remote);
});

final businessesProvider = StreamProvider<List<Business>>((ref) {
  return ref.watch(businessRepositoryProvider).watchBusiness();
});

final businessViewModelProvider =
    AsyncNotifierProvider<BusinessViewModel, void>(BusinessViewModel.new);

final currentBusinessIdProvider = Provider<String>((ref) {
  final business = ref.watch(selectedBusinessProvider);

  if (business == null) {
    throw StateError('No business selected.');
  }

  return business.id;
});
