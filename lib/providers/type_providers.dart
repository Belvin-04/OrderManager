import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/type_repository.dart';
import 'package:order_manager/repositories/firebase_type_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_type_remote_data_source.dart';
import 'package:order_manager/viewmodels/types_viewmodel.dart';

final typesRefProvider = Provider<CollectionReference<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(firebaseFirestoreProvider).collection('types');
});

final typeRepositoryProvider = Provider<TypeRepository>((ref) {
  final typesRef = ref.watch(typesRefProvider);
  final businessId = ref.watch(currentBusinessIdProvider);
  final remote = FirebaseTypeRemoteDataSource(typesRef, businessId: businessId);
  return FirebaseTypeRepository(remote, businessId: businessId);
});

final typesViewModelProvider =
    AsyncNotifierProvider<TypesViewModel, List<Type1>>(() {
      return TypesViewModel();
    });

final typesProvider = StreamProvider<List<Type1>>((ref) {
  return ref.watch(typeRepositoryProvider).watchTypes();
});
