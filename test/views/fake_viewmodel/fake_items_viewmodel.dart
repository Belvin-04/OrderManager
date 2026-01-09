import 'package:order_manager/models/item.dart';
import 'package:order_manager/viewmodels/items_viewmodel.dart';

class FakeItemsViewmodel extends ItemsViewmodel {
  Item? savedItem;
  Item? deletedItem;

  @override
  Future<void> deleteItem(Item item) async {
    deletedItem = item;
  }

  @override
  Future<void> saveItem(Item item) async {
    savedItem = item;
  }
}
