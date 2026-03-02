import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';

class OrdersViewModel extends AsyncNotifier<void> {
  Future<void> saveOrder(Order order, {bool isSplit = false}) async {
    final ordersRepo = ref.read(orderRepositoryProvider);

    final item = order.item;
    final type = order.type;
    final int amount = (item.price + (type.price)) * order.quantity;

    final updated = order.copyWith(amount: amount);

    await ordersRepo.saveOrder(updated, isSplit: isSplit);
  }

  Future<void> completeOrder(Order order) async =>
      saveOrder(order.copyWith(status: "completed"));

  Future<void> cancelOrder(Order order) async =>
      saveOrder(order.copyWith(status: "canceled"));

  Future<void> restoreOrder(Order order) async =>
      saveOrder(order.copyWith(status: "pending"));

  Future<void> repeatOrder(Order order) async =>
      saveOrder(order.copyWith(id: "", status: "pending"));

  Future<bool> repeatAllOrders(Table1 table) async {
    final ordersRepo = ref.read(orderRepositoryProvider);
    final orders = await ordersRepo.getOrdersForTable(table.tableNo.toString());
    bool repeated = false;

    for (final order in orders) {
      try {
        if (order.status != "canceled") {
          await repeatOrder(order);
          repeated = true;
        }
      } catch (e) {
        return false;
      }
    }

    return repeated;
  }

  Future<bool> restoreAllOrders(Table1 table) async {
    final ordersRepo = ref.read(orderRepositoryProvider);
    final orders = await ordersRepo.getOrdersForTable(table.tableNo.toString());

    bool restored = false;

    for (final order in orders) {
      try {
        if (order.status == "canceled") {
          await restoreOrder(order);
          restored = true;
        }
      } catch (e) {
        return false;
      }
    }

    return restored;
  }

  Stream<List<Order>> getBillOrdersForTable(String tableNo) async* {
    Stream<List<Order>> orderStream = ref
        .read(orderRepositoryProvider)
        .getBillOrdersForTable(tableNo);
    Map<String, Order> orderMap = {};

    await for (final List<Order> orderList in orderStream) {
      orderMap.clear();
      for (final Order order in orderList) {
        final key = '${order.item.name} ${order.type.getType(1)}';
        if (orderMap.containsKey(key)) {
          final existingOrder = orderMap[key]!;
          final updatedOrder = existingOrder.copyWith(
            quantity: existingOrder.quantity + order.quantity,
            amount: existingOrder.amount + order.amount,
          );
          orderMap[key] = updatedOrder;
        } else {
          orderMap[key] = order;
        }
      }
      List<Order> orders = orderMap.values.toList();
      yield orders;
    }
  }

  Future<bool> createSplitOrders(String tableNo) async {
    Stream<List<Order>> orderStream = ref
        .read(orderRepositoryProvider)
        .getBillOrdersForTable(tableNo);

    await for (final List<Order> orderList in orderStream) {
      for (final Order order in orderList) {
        if (order.quantity == 1) {
          await saveOrder(order.copyWith(id: ""), isSplit: true);
        } else if (order.quantity > 1) {
          try {
            for (int i = 0; i < order.quantity; i++) {
              Order newOrder = order.copyWith(quantity: 1, id: '');
              await saveOrder(newOrder, isSplit: true);
            }
          } catch (e) {
            return false;
          }
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> changeOrderSplitNo(Order order, int splitNo) async {
    Order newOrder = order.copyWith(
      table: order.table.copyWith(splitNo: splitNo),
    );
    try {
      await saveOrder(newOrder, isSplit: true);
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<bool> resetSplitNo(String tableKey, String splitNo) async {
    List<Order> splitOrders = await ref
        .read(orderRepositoryProvider)
        .getSplitOrders(tableKey)
        .first;

    for (final Order order in splitOrders) {
      try {
        if (order.table.splitNo.toString() == splitNo) {
          await saveOrder(
            order.copyWith(table: order.table.copyWith(splitNo: 0)),
            isSplit: true,
          );
        }
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  Future<bool> removeSplitOrdersForTable(String tableNo) {
    return ref.read(orderRepositoryProvider).removeSplitOrdersForTable(tableNo);
  }

  Stream<int> getTotalAmountForTable(String tableKey, {String splitNo = "0"}) {
    return ref
        .read(orderRepositoryProvider)
        .getTotalAmountForTable(tableKey, splitNo: splitNo);
  }

  Future<List<Order>> getOrdersForSplitTable(int tableNo, int splitNo) async {
    return ref
        .read(orderRepositoryProvider)
        .getOrdersForSplitTable(tableNo.toString(), splitNo.toString());
  }

  Future<void> deleteOrder(Order order, {bool isSplit = false}) async {
    return ref
        .read(orderRepositoryProvider)
        .deleteOrder(order, isSplit: isSplit);
  }

  Future<bool> hasAnyOrdersForTable(String tableKey, {bool isSplit = false}) {
    return ref
        .read(orderRepositoryProvider)
        .hasAnyOrdersForTable(tableKey, isSplit: isSplit);
  }

  @override
  FutureOr<void> build() {}
}
