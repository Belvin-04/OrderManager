import 'package:order_manager/models/item.dart';
import 'package:order_manager/repositories/abstract_files/items_repository.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/item_remote_data_source.dart';

class FirebaseItemRepository implements ItemsRepository {
  final ItemRemoteDataSource remote;
  final String businessId;

  FirebaseItemRepository(this.remote, {required this.businessId});

  @override
  Future<void> deleteItem(Item item) {
    return remote.delete(item.id);
  }

  @override
  Future<void> saveItem(Item item) async {
    String id = item.id.isEmpty ? await remote.generateId() : item.id;

    final data = item.copyWith(id: id, businessId: businessId).toMap();
    await remote.save(id, data);
  }

  @override
  Stream<List<Item>> watchItems() {
    return remote.watchItems().map((data) {
      if (data == null) return <Item>[];

      final map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((e) => Item.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  @override
  Future<Item?> getItemById(String id) async {
    if (id.isEmpty) return null;
    final raw = await remote.queryById(id);
    if (raw == null) return null;

    final map = raw as Map;
    final first = map.values.first;
    return Item.fromMap(Map<String, dynamic>.from(first));
  }

  @override
  Future<bool> itemsExist() async {
    return remote.hasItems();
  }
}
