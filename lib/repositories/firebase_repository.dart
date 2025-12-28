import 'package:firebase_database/firebase_database.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/repositories/items_repository.dart';
import 'package:order_manager/repositories/order_repository.dart';
import 'package:order_manager/repositories/table_repository.dart';
import 'package:order_manager/repositories/type_repository.dart';

class FirebaseTypeRepository implements TypeRepository {
  final DatabaseReference typeReference;

  FirebaseTypeRepository(this.typeReference);

  @override
  Stream<List<Type1>> watchTypes() {
    return typeReference.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) {
        return <Type1>[];
      }

      final map = Map<String, dynamic>.from(data as Map);

      return map.values.map((value) {
        return Type1.fromMap(Map<String, dynamic>.from(value));
      }).toList();
    });
  }

  @override
  Future<void> saveType(Type1 type) async {
    var value = await typeReference
        .orderByChild("type")
        .equalTo(type.type)
        .once();

    String id = type.id;
    if (id.isEmpty) {
      id = typeReference.push().key!;
    } else {
      id = type.id;
    }
    Map<String, dynamic> typeMap = type.toMap();
    typeMap['id'] = id;

    Map<String, dynamic> values = {};
    if (value.snapshot.value is Map) {
      if (value.snapshot.value != null) {
        values = Map<String, dynamic>.from(value.snapshot.value as Map);
        values.forEach((key, value) {
          typeMap['id'] = value['id'];
        });
      }
    }
    await typeReference.child(typeMap['id']).set(typeMap);
  }

  @override
  Future<void> deleteType(Type1 type) async {
    await typeReference.child(type.id).remove();
  }

  @override
  Future<Type1?> getType(String typeName) {
    return typeReference.orderByChild("type").equalTo(typeName).once().then((
      value,
    ) {
      if (value.snapshot.value != null) {
        var values = value.snapshot.value as Map;
        final firstValue = values.values.first;
        return Type1.fromMap(Map<String, dynamic>.from(firstValue));
      }
      return null;
    });
  }
}

class FirebaseItemRepository implements ItemsRepository {
  final DatabaseReference itemReference;

  FirebaseItemRepository(this.itemReference);
  @override
  Future<void> deleteItem(Item item) async {
    String id = item.id;
    await itemReference.child(id).remove();
  }

  @override
  Future<void> saveItem(Item item) async {
    var value = await itemReference
        .orderByChild("name")
        .equalTo(item.name)
        .once();

    String id = item.id;
    if (id.isEmpty) {
      id = itemReference.push().key!;
    } else {
      id = item.id;
    }
    final itemMap = item.toMap();
    itemMap['id'] = id;

    var values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map;
      values.forEach((key, value) {
        itemMap['id'] = value['id'];
      });
    }
    await itemReference.child(itemMap['id']).set(itemMap);
  }

  @override
  Stream<List<Item>> watchItems() {
    return itemReference.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) {
        return <Item>[];
      }

      final map = Map<String, dynamic>.from(data as Map);

      return map.values.map((value) {
        return Item.fromMap(Map<String, dynamic>.from(value));
      }).toList();
    });
  }

  @override
  Future<Item?> getItem(String itemName) async {
    return itemReference.orderByChild("name").equalTo(itemName).once().then((
      value,
    ) {
      if (value.snapshot.value != null) {
        final values = value.snapshot.value as Map;
        final firstValue = values.values.first;
        return Item.fromMap(Map<String, dynamic>.from(firstValue));
      }
      return null;
    });
  }
}

class FirebaseTableRepository extends TableRepository {
  final DatabaseReference tablesReference;

  FirebaseTableRepository(this.tablesReference);
  @override
  Future<void> addTable(int tableNo) async {
    final id = tablesReference.push().key!;
    final table = Table1(tableNo: tableNo, id: id);
    await tablesReference.child(table.id).set(table.toMap());
  }

  @override
  Future<Table1?> getLastTable() async {
    final query = tablesReference.orderByChild('table/tableNo').limitToLast(1);
    final event = await query.once();

    if (event.snapshot.value == null) return null;

    final values = event.snapshot.value as Map;
    return Table1.fromMap(Map<String, dynamic>.from(values.values.first));
  }

  @override
  Stream<List<Table1>> watchTables() {
    return tablesReference.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((e) => Table1.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  @override
  Future<void> deleteTableById(String tableId) async {
    await tablesReference.child(tableId).remove();
  }
}

class FirebaseOrderRepository extends OrderRepository {
  final DatabaseReference orderReference;
  final DatabaseReference splitOrderReference;
  FirebaseOrderRepository(
    this.orderReference, {
    required this.splitOrderReference,
  });
  @override
  Future<bool> hasAnyOrdersForTable(String tableKey) async {
    final event = await orderReference.once();
    if (event.snapshot.value == null) return false;

    final orders = event.snapshot.value as Map;
    return orders.values.any((order) {
      Order convertedOrder = Order.fromMap(Map.from(order));
      return convertedOrder.table.tableNo.toString() == tableKey;
    });
  }

  @override
  Future<bool> hasPendingOrdersForTable(String tableKey) async {
    final event = await orderReference
        .orderByChild('table/tableNo')
        .equalTo(int.parse(tableKey))
        .once();

    if (event.snapshot.value == null) return false;

    final orders = event.snapshot.value as Map;
    return orders.values.any((order) => order['status'] == 'pending');
  }

  @override
  Future<void> deleteOrdersForTable(String tableKey) async {
    final event = await orderReference
        .orderByChild('table/tableNo')
        .equalTo(int.parse(tableKey))
        .once();
    if (event.snapshot.value == null) return;

    final orders = event.snapshot.value as Map;
    for (final entry in orders.entries) {
      await orderReference.child(entry.key).remove();
    }
  }

  @override
  Stream<int> getTotalAmountForTable(String tableKey, {String splitNo = "0"}) {
    DatabaseReference reference = splitNo == "0"
        ? orderReference
        : splitOrderReference;
    return reference.onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final orders = event.snapshot.value as Map;
      int total = 0;

      orders.forEach((key, value) {
        Order order = Order.fromMap(value as Map);
        if (order.table.tableNo.toString() == tableKey &&
            order.table.splitNo.toString() == splitNo &&
            value['status'] != 'canceled') {
          total += (value['amount'] as num).toInt();
        }
      });
      return total;
    });
  }

  @override
  Future<Set<int>> getOccupiedTableNos() async {
    final event = await orderReference.once();
    if (event.snapshot.value == null) return {};

    final orders = event.snapshot.value as Map;
    return orders.values.map((o) {
      Order convertedOrder = Order.fromMap(Map.from(o));
      return convertedOrder.table.tableNo;
    }).toSet();
  }

  @override
  Future<List<Order>> getOrdersForTable(String tableKey) async {
    final event = await orderReference.once();
    if (event.snapshot.value == null) return [];

    final orders = event.snapshot.value as Map;
    return orders.values
        .map((v) => Order.fromMap(Map<String, dynamic>.from(v)))
        .where((o) => o.table.tableNo.toString() == tableKey)
        .toList();
  }

  @override
  Future<void> moveOrders(String fromTableKey, String toTableKey) async {
    final event = await orderReference.once();
    if (event.snapshot.value == null) return;

    final orders = event.snapshot.value as Map;
    for (final entry in orders.entries) {
      Order order = Order.fromMap(entry.value as Map);
      if (order.table.tableNo.toString() == fromTableKey) {
        await orderReference.child(entry.key).update({
          'table/tableNo': int.parse(toTableKey),
        });
      }
    }
  }

  @override
  Future<void> saveOrder(Order order, {bool isSplit = false}) async {
    DatabaseReference reference = isSplit
        ? splitOrderReference
        : orderReference;
    final id = order.id.isEmpty ? reference.push().key! : order.id;

    final updated = order.copyWith(id: id);

    await reference.child(id).set(updated.toMap());
  }

  @override
  Future<List<Order>> getOrdersByType(String typeName) async {
    final event = await orderReference.once();

    if (event.snapshot.value == null) return [];

    final map = event.snapshot.value as Map;

    return map.values
        .map((raw) => Order.fromMap(Map<String, dynamic>.from(raw)))
        .where((order) => order.type.getType(1) == typeName)
        .toList();
  }

  @override
  Stream<List<Order>> watchOrdersByStatus(String status, String tableNo) {
    return orderReference.orderByChild("status").equalTo(status).onValue.map((
      event,
    ) {
      if (event.snapshot.value == null) return [];

      final data = event.snapshot.value as Map;

      return data.values
          .map((e) => Order.fromMap(e))
          .where((o) => o.table.tableNo.toString() == tableNo)
          .toList();
    });
  }

  @override
  Stream<List<Order>> getBillOrdersForTable(String tableNo) {
    return orderReference
        .orderByChild("table/tableNo")
        .equalTo(int.parse(tableNo))
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return [];

          final map = Map<String, dynamic>.from(event.snapshot.value as Map);

          return map.values
              .map((value) => Order.fromMap(Map<String, dynamic>.from(value)))
              .where(
                (order) =>
                    order.status == "pending" || order.status == "completed",
              )
              .toList();
        });
  }

  @override
  Map<String, int> getBillTotals(List<Order> orders) {
    int totalAmount = 0;
    int totalQuantity = 0;

    for (final order in orders) {
      totalAmount += order.amount;
      totalQuantity += order.quantity;
    }

    return {"amount": totalAmount, "quantity": totalQuantity};
  }

  @override
  Stream<List<Order>> watchSplitOrders(String tableNo) {
    return splitOrderReference
        .orderByChild("table/tableNo")
        .equalTo(int.parse(tableNo))
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return [];

          final data = event.snapshot.value as Map;

          return data.values
              .map((e) => Order.fromMap(e))
              .where((o) => o.table.splitNo == 0)
              .toList();
        });
  }

  @override
  Stream<List<Order>> getSplitOrders(String tableNo) {
    return splitOrderReference
        .orderByChild("table/tableNo")
        .equalTo(int.parse(tableNo))
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return [];

          final data = event.snapshot.value as Map;

          return data.values.map((e) => Order.fromMap(e)).toList();
        });
  }

  @override
  Future<bool> removeSplitOrdersForTable(String tableNo) async {
    final event = await splitOrderReference
        .orderByChild("table/tableNo")
        .equalTo(int.parse(tableNo))
        .once();
    if (event.snapshot.value == null) return true;

    final map = event.snapshot.value as Map;

    final List<Order> splitOrders = map.values
        .map((raw) => Order.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
    try {
      for (final Order order in splitOrders) {
        await deleteOrder(order);
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  @override
  Future<void> deleteOrder(Order order) async {
    String id = order.id;
    await splitOrderReference.child(id).remove();
  }
}
