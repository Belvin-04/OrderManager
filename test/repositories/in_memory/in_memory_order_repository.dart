import 'dart:async';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/repositories/order_repository.dart';

class InMemoryOrderRepository implements OrderRepository {
  final Map<String, Order> _orders = {};
  final Map<String, Order> _splitOrders = {};

  final StreamController<List<Order>> _ordersController =
      StreamController<List<Order>>.broadcast(onListen: () {});

  final StreamController<List<Order>> _splitController =
      StreamController<List<Order>>.broadcast(onListen: () {});

  void _emitOrders() {
    _ordersController.add(_orders.values.toList());
  }

  void _emitSplitOrders() {
    _splitController.add(_splitOrders.values.toList());
  }

  @override
  Future<void> saveOrder(Order order, {bool isSplit = false}) async {
    final id = order.id.isEmpty
        ? '${isSplit ? "s" : "o"}_${DateTime.now().microsecondsSinceEpoch}'
        : order.id;

    final updated = order.copyWith(id: id);

    if (isSplit) {
      _splitOrders[id] = updated;
      _emitSplitOrders();
    } else {
      _orders[id] = updated;
      _emitOrders();
    }
  }

  @override
  Future<void> deleteOrder(Order order) async {
    _splitOrders.remove(order.id);
    _emitSplitOrders();
  }

  @override
  Future<List<Order>> getOrdersForTable(String tableKey) async {
    return _orders.values
        .where((o) => o.table.tableNo.toString() == tableKey)
        .toList();
  }

  @override
  Future<List<Order>> getOrdersByItem(String itemName) async {
    return _orders.values.where((o) => o.item.name == itemName).toList();
  }

  @override
  Future<List<Order>> getOrdersByType(String typeName) async {
    return _orders.values.where((o) => o.type.type == typeName).toList();
  }

  @override
  Future<bool> hasAnyOrdersForTable(String tableKey) async {
    return _orders.values.any((o) => o.table.tableNo.toString() == tableKey);
  }

  @override
  Future<bool> hasPendingOrdersForTable(String tableKey) async {
    return _orders.values.any(
      (o) => o.table.tableNo.toString() == tableKey && o.status == 'pending',
    );
  }

  @override
  Future<Set<int>> getOccupiedTableNos() async {
    return _orders.values.map((o) => o.table.tableNo).toSet();
  }

  @override
  Future<void> moveOrders(String fromTableKey, String toTableKey) async {
    _orders.updateAll((key, order) {
      if (order.table.tableNo.toString() == fromTableKey) {
        return order.copyWith(
          table: order.table.copyWith(tableNo: int.parse(toTableKey)),
        );
      }
      return order;
    });
    _emitOrders();
  }

  @override
  Stream<List<Order>> watchOrdersByStatus(String status, String tableNo) {
    return Stream.multi((controller) {
      controller.add(
        _orders.values
            .where(
              (o) =>
                  o.status == status && o.table.tableNo.toString() == tableNo,
            )
            .toList(),
      );

      final sub = _ordersController.stream.listen((orders) {
        controller.add(
          orders
              .where(
                (o) =>
                    o.status == status && o.table.tableNo.toString() == tableNo,
              )
              .toList(),
        );
      });

      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<Order>> getBillOrdersForTable(String tableNo) {
    return Stream.multi((controller) {
      controller.add(
        _orders.values
            .where(
              (o) =>
                  o.table.tableNo.toString() == tableNo &&
                  (o.status == 'pending' || o.status == 'completed'),
            )
            .toList(),
      );

      final sub = _ordersController.stream.listen((orders) {
        controller.add(
          orders
              .where(
                (o) =>
                    o.table.tableNo.toString() == tableNo &&
                    (o.status == 'pending' || o.status == 'completed'),
              )
              .toList(),
        );
      });

      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<Order>> getSplitOrders(String tableNo) {
    return Stream.multi((controller) {
      controller.add(
        _splitOrders.values
            .where((o) => o.table.tableNo.toString() == tableNo)
            .toList(),
      );

      final sub = _splitController.stream.listen((orders) {
        controller.add(
          orders.where((o) => o.table.tableNo.toString() == tableNo).toList(),
        );
      });

      controller.onCancel = sub.cancel;
    });
  }

  @override
  Map<String, int> getBillTotals(List<Order> orders) {
    int amount = 0;
    int quantity = 0;

    for (final order in orders) {
      amount += order.amount;
      quantity += order.quantity;
    }

    return {'amount': amount, 'quantity': quantity};
  }

  @override
  Future<void> deleteOrdersForTable(String tableKey) async {
    _orders.removeWhere((_, o) => o.table.tableNo.toString() == tableKey);
    _emitOrders();
  }

  @override
  Stream<int> getTotalAmountForTable(String tableKey, {String splitNo = "0"}) {
    return getBillOrdersForTable(
      tableKey,
    ).map((orders) => orders.fold(0, (sum, o) => sum + o.amount));
  }

  @override
  Stream<List<Order>> watchSplitOrders(String tableNo) =>
      getSplitOrders(tableNo);

  @override
  Future<bool> removeSplitOrdersForTable(String tableNo) async {
    _splitOrders.removeWhere((_, o) => o.table.tableNo.toString() == tableNo);
    _emitSplitOrders();
    return true;
  }

  void dispose() {
    _ordersController.close();
  }
}
