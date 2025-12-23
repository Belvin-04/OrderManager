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
        return Type1.toType(Map<String, dynamic>.from(value));
      }).toList();
    });
  }

  @override
  Future<void> saveType(Type1 type) async {
    var value = await typeReference
        .orderByChild("type")
        .equalTo(type.getType())
        .once();

    String id = type.getId();
    if (id.isEmpty) {
      id = typeReference.push().key!;
    } else {
      id = type.getId();
    }
    Map typeMap = type.toMap();
    typeMap['id'] = id;

    Map values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        typeMap['id'] = value['id'];
      });
    }
    typeReference.child(typeMap['id']).set(typeMap);
  }

  @override
  Future<void> deleteType(Type1 type) async {
    await typeReference.child(type.getId()).remove();
  }

  @override
  Future<Type1?> getType(String typeName) {
    return typeReference.orderByChild("type").equalTo(typeName).once().then((
      value,
    ) {
      if (value.snapshot.value != null) {
        Map values = value.snapshot.value as Map<dynamic, dynamic>;
        final firstValue = values.values.first;
        return Type1.toType(Map<String, dynamic>.from(firstValue));
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
    String id = item.getId();
    itemReference.child(id).remove();
  }

  @override
  Future<void> saveItem(Item item) async {
    var value = await itemReference
        .orderByChild("name")
        .equalTo(item.getName())
        .once();

    String id = item.getId();
    if (id.isEmpty) {
      id = itemReference.push().key!;
    } else {
      id = item.getId();
    }
    Map itemMap = item.toMap();
    itemMap['id'] = id;

    Map values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        itemMap['id'] = value['id'];
      });
    }
    itemReference.child(itemMap['id']).set(itemMap);
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
        return Item.toItem(Map<String, dynamic>.from(value));
      }).toList();
    });
  }

  @override
  Future<Item?> getItem(String itemName) async {
    return itemReference.orderByChild("name").equalTo(itemName).once().then((
      value,
    ) {
      if (value.snapshot.value != null) {
        Map values = value.snapshot.value as Map<dynamic, dynamic>;
        final firstValue = values.values.first;
        return Item.toItem(Map<String, dynamic>.from(firstValue));
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
    final table = Table1(tableNo, id);
    await tablesReference.child(table.id).set(table.toMap());
  }

  @override
  Future<Table1?> getLastTable() async {
    final query = tablesReference.orderByChild('tableNo').limitToLast(1);
    final event = await query.once();

    if (event.snapshot.value == null) return null;

    final values = event.snapshot.value as Map<dynamic, dynamic>;
    return Table1.toTable(values.values.first);
  }

  @override
  Stream<List<Table1>> watchTables() {
    return tablesReference.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((e) => Table1.toTable(Map<String, dynamic>.from(e)))
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
  FirebaseOrderRepository(this.orderReference);
  @override
  Future<bool> hasAnyOrdersForTable(String tableKey) async {
    final event = await orderReference.once();
    if (event.snapshot.value == null) return false;

    final orders = event.snapshot.value as Map<dynamic, dynamic>;
    return orders.values.any(
      (order) => order['tableNo'].toString() == tableKey,
    );
  }

  @override
  Future<bool> hasPendingOrdersForTable(String tableKey) async {
    final event = await orderReference
        .orderByChild('tableNo')
        .equalTo(int.parse(tableKey))
        .once();

    if (event.snapshot.value == null) return false;

    final orders = event.snapshot.value as Map<dynamic, dynamic>;
    return orders.values.any((order) => order['status'] == 'pending');
  }

  @override
  Future<void> deleteOrdersForTable(String tableKey) async {
    final event = await orderReference
        .orderByChild('tableNo')
        .equalTo(int.parse(tableKey))
        .once();
    if (event.snapshot.value == null) return;

    final orders = event.snapshot.value as Map<dynamic, dynamic>;
    for (final entry in orders.entries) {
      await orderReference.child(entry.key).remove();
    }
  }

  @override
  Stream<int> getTotalAmountForTable(String tableKey) {
    return orderReference.onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final orders = event.snapshot.value as Map<dynamic, dynamic>;
      int total = 0;

      orders.forEach((key, value) {
        if (value['tableNo'].toString() == tableKey &&
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

    final orders = event.snapshot.value as Map<dynamic, dynamic>;
    return orders.values.map((o) => o['tableNo'] as int).toSet();
  }

  @override
  Future<List<Order>> getOrdersForTable(String tableKey) async {
    final event = await orderReference.once();
    if (event.snapshot.value == null) return [];

    final orders = event.snapshot.value as Map<dynamic, dynamic>;
    return orders.values
        .map((v) => Order.toOrder(v))
        .where((o) => o.tableNo.toString() == tableKey)
        .toList();
  }

  @override
  Future<void> moveOrders(String fromTableKey, String toTableKey) async {
    final event = await orderReference.once();
    if (event.snapshot.value == null) return;

    final orders = event.snapshot.value as Map<dynamic, dynamic>;
    for (final entry in orders.entries) {
      if (entry.value['tableNo'].toString() == fromTableKey) {
        await orderReference.child(entry.key).update({
          'tableNo': int.parse(toTableKey),
        });
      }
    }
  }

  @override
  Future<void> saveOrder(Order order) async {
    final id = order.id.isEmpty ? orderReference.push().key! : order.id;

    final updated = order.copyWith(id: id);

    await orderReference.child(id).set(updated.toMap());
  }

  @override
  Future<List<Order>> getOrdersByType(String typeName) async {
    final event = await orderReference.once();

    if (event.snapshot.value == null) return [];

    final map = event.snapshot.value as Map<dynamic, dynamic>;

    return map.values
        .map((raw) => Order.toOrder(raw))
        .where((order) => order.getType(1) == typeName)
        .toList();
  }

  @override
  Stream<List<Order>> watchOrdersByStatus(String status, String tableNo) {
    return orderReference.orderByChild("status").equalTo(status).onValue.map((
      event,
    ) {
      if (event.snapshot.value == null) return [];

      final data = event.snapshot.value as Map<dynamic, dynamic>;

      return data.values
          .map((e) => Order.toOrder(e))
          .where((o) => o.tableNo.toString() == tableNo)
          .toList();
    });
  }

  @override
  Stream<List<Order>> getBillOrdersForTable(String tableNo) {
    return orderReference
        .orderByChild("tableNo")
        .equalTo(int.parse(tableNo))
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return [];

          final map = Map<String, dynamic>.from(event.snapshot.value as Map);

          return map.values
              .map((value) => Order.toOrder(Map<String, dynamic>.from(value)))
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
}
