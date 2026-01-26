import 'dart:async';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/repositories/abstract_files/items_repository.dart';

class InMemoryItemRepository implements ItemsRepository {
  final Map<String, Item> _byId = {};

  late final StreamController<List<Item>> _controller =
      StreamController<List<Item>>.broadcast(
        onListen: () {
          _controller.add(_byId.values.toList());
        },
      );

  void _emit() {
    _controller.add(_byId.values.toList());
  }

  @override
  Stream<List<Item>> watchItems() => _controller.stream;

  @override
  Future<void> saveItem(Item item) async {
    final existing = _byId.values.where((i) => i.name == item.name).toList();

    final String id;
    if (existing.isNotEmpty) {
      id = existing.first.id;
    } else if (item.id.isNotEmpty) {
      id = item.id;
    } else {
      id = 'item_${_byId.length + 1}';
    }

    _byId[id] = item.copyWith(id: id);
    _emit();
  }

  @override
  Future<Item?> getItem(String itemName) async {
    try {
      return _byId.values.firstWhere((i) => i.name == itemName);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteItem(Item item) async {
    _byId.remove(item.id);
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
