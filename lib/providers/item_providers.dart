import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/items_repository.dart';
import 'package:order_manager/repositories/firebase_item_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_item_remote_data_source.dart';
import 'package:order_manager/viewmodels/items_viewmodel.dart';

final itemsRefProvider = Provider<DatabaseReference>((ref) {
  return ref.read(firebaseDatabaseProvider).ref('items');
});

final itemRepositoryProvider = Provider<ItemsRepository>((ref) {
  final itemsRef = ref.read(itemsRefProvider);
  final remote = FirebaseItemRemoteDataSource(itemsRef);
  return FirebaseItemRepository(remote);
});

final itemsProvider = StreamProvider<List<Item>>((ref) {
  return ref.read(itemRepositoryProvider).watchItems();
});

final itemsViewModelProvider = AsyncNotifierProvider<ItemsViewmodel, void>(() {
  return ItemsViewmodel();
});
