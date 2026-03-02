import 'package:order_manager/models/order.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/order_remote_data_source.dart';

class FirebaseOrderRepository extends OrderRepository {
  final OrderRemoteDataSource remote;

  FirebaseOrderRepository(this.remote);

  @override
  Future<bool> hasAnyOrdersForTable(
    String tableKey, {
    bool isSplit = false,
  }) async {
    final raw = isSplit
        ? await remote.getSplitOrdersByTable(int.parse(tableKey))
        : await remote.getAllOrders();
    if (raw == null) return false;

    final map = raw as Map;
    return map.values
        .map((e) => Order.fromMap(Map.from(e)))
        .any((o) => o.table.tableNo.toString() == tableKey);
  }

  @override
  Future<bool> hasPendingOrdersForTable(String tableKey) async {
    final raw = await remote.queryOrdersByTable(int.parse(tableKey));
    if (raw == null) return false;

    final map = raw as Map;
    return map.values.any((o) => o['status'] == 'pending');
  }

  @override
  Future<void> deleteOrdersForTable(String tableKey) async {
    final raw = await remote.queryOrdersByTable(int.parse(tableKey));
    if (raw == null) return;

    final map = raw as Map;
    for (final entry in map.values) {
      Order order = Order.fromMap(entry);
      await deleteOrder(order, isSplit: false);
    }
  }

  @override
  Stream<int> getTotalAmountForTable(String tableKey, {String splitNo = "0"}) {
    final source = splitNo == "0"
        ? remote.watchOrders()
        : remote.watchSplitOrders();

    return source.map((raw) {
      if (raw == null) return 0;

      final map = raw as Map;
      int total = 0;

      for (final v in map.values) {
        final order = Order.fromMap(Map.from(v));
        if (order.table.tableNo.toString() == tableKey &&
            order.table.splitNo.toString() == splitNo &&
            order.status != 'canceled') {
          total += order.amount;
        }
      }
      return total;
    });
  }

  @override
  Future<Set<int>> getOccupiedTableNos() async {
    final raw = await remote.getAllOrders();
    if (raw == null) return {};

    final map = raw as Map;
    return map.values
        .map((v) => Order.fromMap(Map.from(v)).table.tableNo)
        .toSet();
  }

  @override
  Future<List<Order>> getOrdersForTable(String tableKey) async {
    final raw = await remote.getAllOrders();
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((v) => Order.fromMap(Map<String, dynamic>.from(v)))
        .where((o) => o.table.tableNo.toString() == tableKey)
        .toList();
  }

  @override
  Future<List<Order>> getOrdersForSplitTable(
    String tableKey,
    String splitNo,
  ) async {
    final raw = await remote.getSplitOrdersByTable(int.parse(tableKey));
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((v) => Order.fromMap(Map<String, dynamic>.from(v)))
        .where(
          (o) =>
              o.table.tableNo.toString() == tableKey &&
              o.table.splitNo.toString() == splitNo,
        )
        .toList();
  }

  @override
  Future<void> moveOrders(String fromTableKey, String toTableKey) async {
    final raw = await remote.getAllOrders();
    if (raw == null) return;

    final map = raw as Map;
    for (final entry in map.entries) {
      final order = Order.fromMap(Map.from(entry.value));
      if (order.table.tableNo.toString() == fromTableKey) {
        await remote.updateTableNo(entry.key, int.parse(toTableKey));
      }
    }
  }

  @override
  Future<void> saveOrder(Order order, {bool isSplit = false}) async {
    final id = order.id.isEmpty
        ? await remote.generateId(isSplit: isSplit)
        : order.id;

    final updated = order.copyWith(id: id);
    await remote.save(id, updated.toMap(), isSplit: isSplit);
  }

  @override
  Future<List<Order>> getOrdersByType(String typeName) async {
    final raw = await remote.queryOrdersByType(typeName);
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((v) => Order.fromMap(Map<String, dynamic>.from(v)))
        .toList();
  }

  @override
  Future<List<Order>> getOrdersByItem(String itemName) async {
    final raw = await remote.queryOrdersByItem(itemName);
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((v) => Order.fromMap(Map<String, dynamic>.from(v)))
        .toList();
  }

  @override
  Stream<List<Order>> watchOrdersByStatus(String status, String tableNo) {
    return remote.watchOrders().map((raw) {
      if (raw == null) return [];

      final map = raw as Map;
      return map.values
          .map((e) => Order.fromMap(Map.from(e)))
          .where(
            (o) => o.status == status && o.table.tableNo.toString() == tableNo,
          )
          .toList();
    });
  }

  @override
  Stream<List<Order>> getBillOrdersForTable(String tableNo) {
    return remote.watchOrders().map((raw) {
      if (raw == null) return [];

      final map = raw as Map;
      return map.values
          .map((e) => Order.fromMap(Map.from(e)))
          .where(
            (o) =>
                o.table.tableNo.toString() == tableNo &&
                (o.status == 'pending' || o.status == 'completed'),
          )
          .toList();
    });
  }

  @override
  Map<String, int> getBillTotals(List<Order> orders) {
    int amount = 0;
    int qty = 0;

    for (final o in orders) {
      amount += o.amount;
      qty += o.quantity;
    }

    return {'amount': amount, 'quantity': qty};
  }

  @override
  Stream<List<Order>> watchSplitOrders(String tableNo) {
    return remote.watchSplitOrders().map((raw) {
      if (raw == null) return [];

      final map = raw as Map;
      return map.values
          .map((e) => Order.fromMap(Map.from(e)))
          .where(
            (o) =>
                o.table.splitNo == 0 && o.table.tableNo.toString() == tableNo,
          )
          .toList();
    });
  }

  @override
  Stream<List<Order>> getSplitOrders(String tableNo) {
    return remote.watchSplitOrders().map((raw) {
      if (raw == null) return [];

      final map = raw as Map;
      return map.values.map((e) => Order.fromMap(Map.from(e))).toList();
    });
  }

  @override
  Future<bool> removeSplitOrdersForTable(String tableNo) async {
    final raw = await remote.getSplitOrdersByTable(int.parse(tableNo));
    if (raw == null) return true;

    final map = raw as Map;
    try {
      for (final v in map.values) {
        final order = Order.fromMap(Map<String, dynamic>.from(v));
        await deleteOrder(order, isSplit: true);
      }
    } catch (_) {
      return false;
    }
    return true;
  }

  @override
  Future<void> deleteOrder(Order order, {required bool isSplit}) {
    return remote.delete(order.id, isSplit: isSplit);
  }

  @override
  Stream<List<Order>> watchOrdersForTable(String tableKey) {
    return remote.watchOrders().map((raw) {
      if (raw == null) return [];

      final map = raw as Map;
      return map.values
          .map((e) => Order.fromMap(Map.from(e)))
          .where((o) => o.table.tableNo.toString() == tableKey)
          .toList();
    });
  }
}
