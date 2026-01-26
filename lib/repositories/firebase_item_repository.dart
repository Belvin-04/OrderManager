import 'package:order_manager/models/item.dart';
import 'package:order_manager/repositories/abstract_files/items_repository.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/item_remote_data_source.dart';

class FirebaseItemRepository implements ItemsRepository {
  final ItemRemoteDataSource remote;

  FirebaseItemRepository(this.remote);

  @override
  Future<void> deleteItem(Item item) {
    return remote.delete(item.id);
  }

  @override
  Future<void> saveItem(Item item) async {
    final existing = await remote.queryByName(item.name);

    String id;

    if (existing is Map && existing.isNotEmpty) {
      id = existing.values.first['id'];
    } else {
      id = await remote.generateId();
    }

    final data = item.toMap()..['id'] = id;
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
  Future<Item?> getItem(String itemName) async {
    final raw = await remote.queryByName(itemName);
    if (raw == null) return null;

    final map = raw as Map;
    final first = map.values.first;
    return Item.fromMap(Map<String, dynamic>.from(first));
  }
}
