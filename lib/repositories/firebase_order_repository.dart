import 'package:order_manager/models/order.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/order_remote_data_source.dart';

class FirebaseOrderRepository extends OrderRepository {
  final OrderRemoteDataSource remote;
  final String businessId;

  FirebaseOrderRepository(this.remote, {required this.businessId});

  @override
  Future<bool> hasAnyOrdersForTable(
    String tableKey, {
    bool isSplit = false,
  }) async {
    final raw = await remote.getOrdersBy(
      fields: ['table.tableNo'],
      values: [int.parse(tableKey)],
      isEqualTo: [true],
      isSplit: isSplit,
      limitToOne: true,
    );
    return raw != null;
  }

  @override
  Future<bool> hasPendingOrdersForTable(String tableKey) async {
    final raw = await remote.getOrdersBy(
      fields: ['table.tableNo', 'status'],
      values: [int.parse(tableKey), 'pending'],
      isEqualTo: [true, true],
      limitToOne: true,
    );
    return raw != null;
  }

  @override
  Future<void> deleteOrdersForTable(String tableKey) async {
    final raw = await remote.getOrdersBy(
      fields: ['table.tableNo'],
      values: [int.parse(tableKey)],
      isEqualTo: [true],
    );
    if (raw == null) return;

    final map = raw as Map;
    for (final entry in map.values) {
      final Order order = Order.fromMap(Map<String, dynamic>.from(entry));
      await deleteOrder(order, isSplit: false);
    }
  }

  @override
  Stream<int> getTotalAmountForTable(String tableKey, {String splitNo = "0"}) {
    final source = splitNo == "0"
        ? remote.watchOrders(
            fields: ['table.tableNo', 'status'],
            values: [int.parse(tableKey), 'canceled'],
            isEqualTo: [true, false],
          )
        : remote.watchOrders(
            fields: ['table.tableNo', 'table.splitNo', 'status'],
            values: [int.parse(tableKey), int.parse(splitNo), 'canceled'],
            isEqualTo: [true, true, false],
            isSplit: true,
          );

    return source.map((raw) {
      if (raw == null) return 0;

      final map = raw as Map;
      int total = 0;

      for (final v in map.values) {
        final order = Order.fromMap(Map<String, dynamic>.from(v));
        total += order.amount;
      }
      return total;
    });
  }

  @override
  Future<Set<int>> getOccupiedTableNos() async {
    final raw = await remote.getOrdersBy(fields: [], values: [], isEqualTo: []);
    if (raw == null) return {};

    final map = raw as Map;
    return map.values
        .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
        .map((order) => order.table.tableNo)
        .toSet();
  }

  @override
  Future<List<Order>> getOrdersForTable(String tableKey) async {
    final raw = await remote.getOrdersBy(
      fields: ['table.tableNo'],
      values: [int.parse(tableKey)],
      isEqualTo: [true],
    );
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<Order>> getNonCanceledOrdersForTable(String tableKey) async {
    final raw = await remote.getOrdersBy(
      fields: ['table.tableNo', 'status'],
      values: [int.parse(tableKey), 'canceled'],
      isEqualTo: [true, false],
    );
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<Order>> getCanceledOrdersForTable(String tableKey) async {
    final raw = await remote.getOrdersBy(
      fields: ['table.tableNo', 'status'],
      values: [int.parse(tableKey), 'canceled'],
      isEqualTo: [true, true],
    );
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<Order>> getOrdersForSplitTable(
    String tableKey,
    String splitNo,
  ) async {
    final raw = await remote.getOrdersBy(
      fields: ['table.tableNo', 'table.splitNo'],
      values: [int.parse(tableKey), int.parse(splitNo)],
      isEqualTo: [true, true],
    );
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> moveOrders(String fromTableKey, String toTableKey) async {
    final raw = await remote.getOrdersBy(
      fields: ['table.tableNo'],
      values: [int.parse(fromTableKey)],
      isEqualTo: [true],
    );
    if (raw == null) return;

    final map = raw as Map;
    for (final entry in map.entries) {
      await remote.updateTableNo(entry.key, int.parse(toTableKey));
    }
  }

  @override
  Future<void> saveOrder(Order order, {bool isSplit = false}) async {
    final id = order.id.isEmpty
        ? await remote.generateId(isSplit: isSplit)
        : order.id;

    final updated = order.copyWith(id: id, businessId: businessId);
    await remote.save(id, updated.toMap(), isSplit: isSplit);
  }

  @override
  Future<List<Order>> getOrdersByType(String typeName) async {
    final raw = await remote.getOrdersBy(
      fields: ['type.type'],
      values: [typeName],
      isEqualTo: [true],
    );
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<Order>> getOrdersByItem(String itemName) async {
    final raw = await remote.getOrdersBy(
      fields: ['item.name'],
      values: [itemName],
      isEqualTo: [true],
    );
    if (raw == null) return [];

    final map = raw as Map;
    return map.values
        .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Stream<List<Order>> watchOrdersByStatus(String status, String tableNo) {
    return remote
        .watchOrders(
          fields: ['table.tableNo', 'status'],
          values: [int.parse(tableNo), status],
          isEqualTo: [true, true],
        )
        .map((raw) {
          if (raw == null) return [];

          final map = raw as Map;
          return map.values
              .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        });
  }

  @override
  Stream<List<Order>> watchNonCanceledOrdersForTable(String tableNo) {
    return remote
        .watchOrders(
          fields: ['table.tableNo', 'status'],
          values: [int.parse(tableNo), 'canceled'],
          isEqualTo: [true, false],
        )
        .map((raw) {
          if (raw == null) return [];

          final map = raw as Map;
          return map.values
              .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
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
  Stream<List<Order>> watchUnassignedSplitOrdersForTable(String tableNo) {
    return remote
        .watchOrders(
          fields: ['table.tableNo', 'table.splitNo'],
          values: [int.parse(tableNo), 0],
          isEqualTo: [true, true],
          isSplit: true,
        )
        .map((raw) {
          if (raw == null) return [];

          final map = raw as Map;
          return map.values
              .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        });
  }

  @override
  Stream<List<Order>> watchAssignedSplitOrdersForTable(
    String tableNo,
    String splitNo,
  ) {
    return remote
        .watchOrders(
          fields: ['table.tableNo', 'table.splitNo'],
          values: [int.parse(tableNo), int.parse(splitNo)],
          isEqualTo: [true, true],
          isSplit: true,
        )
        .map((raw) {
          if (raw == null) return [];

          final map = raw as Map;
          return map.values
              .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        });
  }

  @override
  Future<bool> removeSplitOrdersForTable(String tableNo) async {
    final raw = await remote.getOrdersBy(
      fields: ['table.tableNo'],
      values: [int.parse(tableNo)],
      isEqualTo: [true],
      isSplit: true,
    );
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
    return remote
        .watchOrders(
          fields: ['table.tableNo'],
          values: [int.parse(tableKey)],
          isEqualTo: [true],
        )
        .map((raw) {
          if (raw == null) return [];

          final map = raw as Map;
          return map.values
              .map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        });
  }
}
