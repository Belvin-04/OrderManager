import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/providers/item_providers.dart';
import 'package:order_manager/providers/order_providers.dart';

class ItemsViewmodel extends AsyncNotifier<void> {
  Future<void> saveItem(Item item) async {
    final itemsRepo = ref.read(itemRepositoryProvider);
    final oldItem = item.id.isNotEmpty
        ? await itemsRepo.getItemById(item.id)
        : null;
    await itemsRepo.saveItem(item);
    if (oldItem == null) return;
    await updateOrderPricesAndNames(oldItem, item);
  }

  Future<void> updateOrderPricesAndNames(Item oldItem, Item item) async {
    final ordersRepo = ref.read(orderRepositoryProvider);
    final orders = await ordersRepo.getOrdersByItem(oldItem.name);
    if (orders.isEmpty) return;

    final List<Order> updated = [];
    for (final order in orders) {
      final newAmount = (item.price + order.type.price) * order.quantity;
      updated.add(order.copyWith(amount: newAmount, item: item));
    }
    await ordersRepo.saveOrders(updated);
  }

  Future<bool> deleteItem(Item item) async {
    final canDelete = await canDeleteItem(item);
    if (!canDelete) return false;
    await ref.read(itemRepositoryProvider).deleteItem(item);
    return true;
  }

  Future<bool> canDeleteItem(Item item) async {
    final orders = await ref
        .read(orderRepositoryProvider)
        .getOrdersByItem(item.name);
    return orders.isEmpty;
  }

  @override
  FutureOr<void> build() {}
}
