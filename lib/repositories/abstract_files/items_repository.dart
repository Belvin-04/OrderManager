import 'package:order_manager/models/item.dart';

abstract class ItemsRepository {
  Stream<List<Item>> watchItems();
  Future<Item?> getItem(String itemName);
  Future<void> saveItem(Item item);
  Future<void> deleteItem(Item item);
  Future<Item?> getItemById(String id);
}
