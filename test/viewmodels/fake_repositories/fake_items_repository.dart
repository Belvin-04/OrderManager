import 'package:order_manager/models/item.dart';
import 'package:order_manager/repositories/items_repository.dart';

class FakeItemsRepository implements ItemsRepository {
  List<Item> items = [];
  final List<Item> deletedItems = [];
  Item? lastSavedItem;

  @override
  Stream<List<Item>> watchItems() async* {
    yield items;
  }

  @override
  Future<void> saveItem(Item item) async {
    lastSavedItem = item;
    items.removeWhere((i) => i.id == item.id);
    items.add(item);
  }

  @override
  Future<Item?> getItem(String itemName) async {
    try {
      return items.firstWhere((i) => i.name == itemName);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteItem(Item item) async {
    deletedItems.add(item);
    items.removeWhere((i) => i.id == item.id);
  }
}
