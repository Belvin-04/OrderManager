import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/items_repository.dart';
import 'package:order_manager/repositories/firebase_item_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_item_remote_data_source.dart';
import 'package:order_manager/viewmodels/items_viewmodel.dart';

final itemsRefProvider = Provider<CollectionReference<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(firebaseFirestoreProvider).collection('items');
});

final itemRepositoryProvider = Provider<ItemsRepository>((ref) {
  final itemsRef = ref.watch(itemsRefProvider);
  final businessId = ref.watch(currentBusinessIdProvider);
  final remote = FirebaseItemRemoteDataSource(itemsRef, businessId: businessId);
  return FirebaseItemRepository(remote, businessId: businessId);
});

final itemsProvider = StreamProvider<List<Item>>((ref) {
  return ref.watch(itemRepositoryProvider).watchItems();
});

final itemsViewModelProvider = AsyncNotifierProvider<ItemsViewmodel, void>(() {
  return ItemsViewmodel();
});
