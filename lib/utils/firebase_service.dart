import 'package:firebase_database/firebase_database.dart';
import 'package:order_manager/modal/order.dart';
import 'package:order_manager/modal/table.dart';
import 'package:order_manager/utils/ThemeProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../modal/item.dart';
import '../modal/type.dart';

class FirebaseService {
  FirebaseDatabase database = FirebaseDatabase.instance;
  late final DatabaseReference tableReference = database.ref("tables");
  late final DatabaseReference orderReference = database.ref("orders");
  late DatabaseReference typeReference = database.ref("types");
  late DatabaseReference itemReference = database.ref("items");

  FirebaseService() {
    enableOfflineFeatures();
  }

  Future<void> addTable() async {
    int tableNo = 0;
    Query tableNoQuery = tableReference.orderByChild('tableNo').limitToLast(1);
    var value = await tableNoQuery.once();

    Map values = {};
    if (value.snapshot.value == null) {
      tableNo++;
    } else {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        tableNo = value['tableNo'];
        tableNo++;
      });
    }
    String id = tableReference.push().key!;
    Map tableMap = Table1(tableNo, id).toMap();
    tableReference.child(id).set(tableMap);
    return;
  }

  Future<int> clearTable(int tableNo) async {
    var value =
        await orderReference.orderByChild("tableNo").equalTo(tableNo).once();
    Map values = {};
    List temp = [];
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        if (value["status"] == "pending") {
          temp.add(1);
        }
      });
      if (temp.length != 0) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 2;
    }
  }

  void deleteItem(Item item) {
    String id = item.getId();
    itemReference.child(id).remove();
  }

  void deleteOrder(Order order) {
    orderReference.child(order.getId()).remove();
  }

  void deleteType(Type1 type) {
    String id = type.getId();

    DatabaseReference typeReference1 = typeReference.child(id);
    typeReference1.remove();
  }

  void enableOfflineFeatures() {
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);

    tableReference.keepSynced(true);
    orderReference.keepSynced(true);
    typeReference.keepSynced(true);
    itemReference.keepSynced(true);
  }

  Future<List<Order>> getTableOrders(Table1 table) async {
    var value = await orderReference
        .orderByChild("tableNo")
        .equalTo(table.getTableNo())
        .once();

    List<Order> orderList = [];
    Map values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        if (value['status'] != "canceled") {
          orderList.add(Order.toOrder(value));
        }
      });
      return orderList;
    }
    return [];
  }

  Future<List<Order>> getAllTableOrders(Table1 table) async {
    var value = await orderReference
        .orderByChild("tableNo")
        .equalTo(table.getTableNo())
        .once();

    List<Order> orderList = [];
    Map values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        orderList.add(Order.toOrder(value));
      });
      return orderList;
    }
    return [];
  }

  Future<bool> isOrderExists(int tableNo) async {
    bool isThereOrder = false;
    var value = await orderReference.once();
    Map orders = {};
    if (value.snapshot.value != null) {
      orders = value.snapshot.value as Map<dynamic, dynamic>;
      orders.forEach((key, order) {
        if (order['tableNo'] == tableNo) {
          isThereOrder = true;
        }
      });
    }
    return isThereOrder;
  }

  Future<int> removeTable() async {
    String? tableId;
    int? tableNo;
    Query tableNoQuery = tableReference.orderByChild('tableNo').limitToLast(1);
    var value = await tableNoQuery.once();
    Map values = {};
    if (value.snapshot.value == null) {
      return 0;
    } else {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        tableId = key;
        tableNo = value['tableNo'];
      });

      var orderExists = await isOrderExists(tableNo!);
      if (!orderExists) {
        tableReference.child(tableId!).remove();
        return 1;
      } else {
        return 2;
      }
    }
  }

  Future<Map> getAllTypes() async {
    Map typeMap = Map();
    var value = await typeReference.once();
    Map values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        typeMap[value['type']] = value['price'];
      });
    }
    return typeMap;
  }

  Future<Map> getAllItems() async {
    Map itemMap = Map();
    var value = await itemReference.once();
    Map values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        itemMap[value['name']] = value['price'];
      });
    }
    return itemMap;
  }

  Future<void> saveOrder(Order order) async {
    Map itemMap = await getAllItems();
    Map typeMap = await getAllTypes();
    typeMap["None"] = 0;
    String id = order.getId();
    if (id.isEmpty) {
      id = orderReference.push().key!;
    } else {
      id = order.getId();
    }
    Map orderMap = order.toMap();
    orderMap['id'] = id;
    orderMap['amount'] =
        (itemMap[order.getItemName()] + typeMap[order.getType(1)]) *
            order.getQuantity();
    orderReference.child(orderMap['id']).set(orderMap);

    return;
  }

  Future<void> completeOrder(Order order) async {
    order.setStatus("completed");
    await saveOrder(order);
    return;
  }

  Future<void> cancelOrder(Order order) async {
    order.setStatus("canceled");
    await saveOrder(order);
    return;
  }

  Future<void> restoreOrder(Order order) async {
    order.setStatus("pending");
    await saveOrder(order);
    return;
  }

  Future<void> repeatOrder(Order order) async {
    order.setId("");
    order.setStatus("pending");
    await saveOrder(order);
    return;
  }

  Future<bool> repeatAllOrder(Table1 table) async {
    var value = await orderReference
        .orderByChild("tableNo")
        .equalTo(table.getTableNo())
        .once();

    bool check = false;
    Map values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      for (var entry in values.entries) {
        var order = entry.value;
        if (order['status'] != "canceled") {
          await repeatOrder(Order.toOrder(order));
          check = true;
        }
      }
      return check;
    }
    return check;
  }

  Future<bool> restoreAllOrder(Table1 table) async {
    var value = await orderReference
        .orderByChild("tableNo")
        .equalTo(table.getTableNo())
        .once();

    bool check = false;
    Map values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      for (var entry in values.entries) {
        var order = entry.value;
        if (order['status'] == "canceled") {
          await restoreOrder(Order.toOrder(order));
          check = true;
        }
      }
      return check;
    }
    return check;
  }

  Future<void> saveItem(Item item) async {
    var value =
        await itemReference.orderByChild("name").equalTo(item.getName()).once();

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
    return;
  }

  void saveOrderSwap(Order order) {
    Map orderMap = order.toMap();
    orderReference.child(orderMap['id']).set(orderMap);
  }

  void showSnackBar(String message, BuildContext context) {
    SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<int> swapTable(
      BuildContext context,int tableNo, List<Table1> tableList) async {
    List<int> totalTables = [];
    List<Order> orderList = [];
    Set selectedTableOrderCheckSet = Set();
    tableList.forEach((element) {
      totalTables.add(element.getTableNo());
    });
    Set occupiedTables = Set();
    var value = await orderReference.once();
    Map values = {};
    if (value.snapshot.value != null) {
      values = value.snapshot.value as Map<dynamic, dynamic>;
      values.forEach((key, value) {
        occupiedTables.add(value["tableNo"]);
        if (value["tableNo"] == tableNo) {
          selectedTableOrderCheckSet.add(1);
          orderList.add(Order.toOrder(value));
        }
      });
      if (selectedTableOrderCheckSet.length != 0) {
        if (occupiedTables.length != 0) {
          occupiedTables.forEach((element) {
            totalTables.remove(element);
          });
        }
        if (totalTables.length != 0) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Select Table No. to swap the order"),
                  content: Container(
                    width: 200,
                    height: 200,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: totalTables.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color:
                                Provider.of<ThemeProvider>(context).isdarkMode
                                    ? Colors.grey.shade900
                                    : Colors.white,
                            child: ListTile(
                              title: Text("Table No. : ${totalTables[index]}"),
                              onTap: () {
                                orderList.forEach((element) {
                                  element.setTableNo(totalTables[index]);
                                  saveOrderSwap(element);
                                });
                                Navigator.pop(context);
                                showSnackBar(
                                    "Orders swapped from Table : $tableNo to Table : ${totalTables[index]}",
                                    context);
                              },
                            ),
                          );
                        }),
                  ),
                );
              });
          return 0;
        } else {
          return 1;
        }
      } else {
        return 2;

      }
    } else {
      return 3;

    }
  }

  Future<void> saveType(Type1 type) async {
    var value =
        await typeReference.orderByChild("type").equalTo(type.getType()).once();

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
    return;
  }
}
