import 'package:order_manager/models/item.dart';

abstract class ItemsRepository {
  Stream<List<Item>> watchItems();
  Future<void> saveItem(Item item);
  Future<void> deleteItem(Item item);
  Future<Item?> getItemById(String id);
  Future<bool> itemsExist();
}
