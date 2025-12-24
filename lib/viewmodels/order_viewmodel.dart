import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';

final ordersViewModelProvider = AsyncNotifierProvider<OrdersViewModel, void>(
  () {
    return OrdersViewModel();
  },
);

final cancelledOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref
      .watch(orderRepositoryProvider)
      .watchOrdersByStatus("canceled", tableNo);
});

final pendingOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref
      .watch(orderRepositoryProvider)
      .watchOrdersByStatus("pending", tableNo);
});

final completedOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref
      .watch(orderRepositoryProvider)
      .watchOrdersByStatus("completed", tableNo);
});

final billOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref
      .read(ordersViewModelProvider.notifier)
      .getBillOrdersForTable(tableNo);
});

final billTotalsProvider = Provider.family<Map<String, int>, String>((
  ref,
  tableNo,
) {
  final repo = ref.watch(orderRepositoryProvider);
  final orders = ref.watch(billOrdersProvider(tableNo)).value ?? [];
  return repo.getBillTotals(orders);
});

class OrdersViewModel extends AsyncNotifier<void> {
  Future<void> saveOrder(Order order) async {
    final itemsRepo = ref.read(itemRepositoryProvider);
    final typesRepo = ref.read(typeRepositoryProvider);
    final ordersRepo = ref.read(orderRepositoryProvider);

    final item = await itemsRepo.getItem(order.itemName);
    final type = await typesRepo.getType(order.getType(1));
    final int amount = (item!.price + (type?.price ?? 0)) * order.quantity;

    final updated = order.copyWith(amount: amount);

    await ordersRepo.saveOrder(updated);
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
        final key = '${order.itemName} ${order.getType(1)}';
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

  @override
  FutureOr<void> build() {}
}
