import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/modal/Order.dart';
import 'package:order_manager/modal/Table.dart';

class Orders extends StatefulWidget {
  final Table1 table;
  final FirebaseApp app;
  Orders(this.table, this.app);

  @override
  _OrdersState createState() => _OrdersState(table, app);
}

class _OrdersState extends State<Orders> {
  final _formStateKey = GlobalKey<FormState>();
  Table1 table;
  FirebaseApp app;
  _OrdersState(this.table, this.app);
  FirebaseDatabase database;
  DatabaseReference orderReference;
  DatabaseReference itemReference;

  @override
  void initState() {
    super.initState();
    database = FirebaseDatabase(app: app);
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    itemReference = database.reference().child("items");
    orderReference = database.reference().child("orders");
    itemReference.keepSynced(true);
    orderReference.keepSynced(true);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          tooltip: "Take New Order",
          child: Icon(Icons.add),
          onPressed: () {
            showSaveOrderDialog(
                Order(0, "", "", table.getTableNo(), "", "pending", ""));
          },
        ),
        appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(
                  child: Text("Pending Orders"),
                ),
                Tab(
                  child: Text("Completed Orders"),
                ),
                Tab(
                  child: Text("Canceled Orders"),
                ),
              ],
            ),
            title: Text("Table ${table.getTableNo()}: Orders"),
            actions: [
              PopupMenuButton(onSelected: (value) {
                switch (value) {
                  case "Repeat all":
                    {
                      repeatAllOrder(context);
                      break;
                    }
                  case "Restore all":
                    {
                      restoreAllOrder(context);
                      break;
                    }
                }
              }, itemBuilder: (BuildContext context) {
                return ["Repeat all", "Restore all"].map((choice) {
                  return PopupMenuItem(
                    child: Text(choice),
                    value: choice,
                  );
                }).toList();
              })
            ]),
        body: WillPopScope(
          onWillPop: () {
            Navigator.pop(context);
            return Future.value(true);
          },
          child: TabBarView(
            children: [
              pendingOrdersList(),
              completedOrdersList(),
              canceledOrdersList(),
            ],
          ),
        ),
      ),
    );
  }

  updateList() {
    setState(() {});
  }

  Widget pendingOrdersList() {
    List orderList = [];
    return FutureBuilder(
        future: orderReference
            .orderByChild("tableNo")
            .equalTo(table.getTableNo())
            .once(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            orderList.clear();
            Map values = snapshot.data.value;
            if (values != null) {
              values.forEach((key, value) {
                if (value['status'] == "pending") {
                  orderList.add(Order.toOrder(value));
                }
              });
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(orderList[index].getData()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          child: Tooltip(
                            message: "Complete Order",
                            child: Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () {
                            completeOrder(orderList[index]);
                          },
                        ),
                        Container(
                          height: 0,
                          width: 0,
                          margin: EdgeInsets.only(right: 10.0),
                        ),
                        GestureDetector(
                          child: Tooltip(
                            message: "Edit Order",
                            child: Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                          ),
                          onTap: () {
                            showSaveOrderDialog(orderList[index]);
                          },
                        ),
                        Container(
                          height: 0,
                          width: 0,
                          margin: EdgeInsets.only(right: 10.0),
                        ),
                        GestureDetector(
                          child: Tooltip(
                            message: "Cancel Order",
                            child: Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                          onTap: () {
                            cancelOrder(orderList[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return Center(child: CircularProgressIndicator());
        });
  }

  Widget completedOrdersList() {
    List orderList = [];
    return FutureBuilder(
        future:
            orderReference.orderByChild("status").equalTo("completed").once(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            orderList.clear();
            Map values = snapshot.data.value;
            if (values != null) {
              values.forEach((key, value) {
                if (value['tableNo'] == table.getTableNo()) {
                  orderList.add(Order.toOrder(value));
                }
              });
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(orderList[index].getData()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          child: Tooltip(
                            message: "Repeat Order",
                            child: Icon(
                              Icons.replay_rounded,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () {
                            repeatOrder(orderList[index]);
                            showSnackBar(
                                "Order Repeated Successfully...", context);
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Center(child: CircularProgressIndicator());
        });
  }

  Widget canceledOrdersList() {
    List orderList = [];
    return FutureBuilder(
        future:
            orderReference.orderByChild("status").equalTo("canceled").once(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            orderList.clear();
            Map values = snapshot.data.value;
            if (values != null) {
              values.forEach((key, value) {
                if (value['tableNo'] == table.getTableNo()) {
                  orderList.add(Order.toOrder(value));
                }
              });
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(orderList[index].getData()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          child: Tooltip(
                            message: "Restore Order",
                            child: Icon(
                              Icons.restore,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () {
                            restoreOrder(orderList[index]);
                            showSnackBar(
                                "Order Restored Successfully...", context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Center(child: CircularProgressIndicator());
        });
  }

  void saveOrder(Order order) {
    String id = order.getId();
    if (id.isEmpty) {
      id = orderReference.push().key;
    } else {
      id = order.getId();
    }
    Map orderMap = order.toMap();
    orderMap['id'] = id;
    orderReference.child(orderMap['id']).set(orderMap);
    updateList();
  }

  void completeOrder(Order order) {
    order.setStatus("completed");
    saveOrder(order);
    updateList();
    showSnackBar("Order Completed Successfully...", context);
  }

  void cancelOrder(Order order) {
    order.setStatus("canceled");
    saveOrder(order);
    updateList();
    showSnackBar("Order Canceled Successfully...", context);
  }

  void restoreOrder(Order order) {
    order.setStatus("pending");
    saveOrder(order);
    updateList();
  }

  void repeatOrder(Order order) {
    order.setId("");
    order.setStatus("pending");
    saveOrder(order);
    updateList();
  }

  void repeatAllOrder(BuildContext context) {
    orderReference
        .orderByChild("tableNo")
        .equalTo(table.getTableNo())
        .once()
        .then((value) {
      if (value != null) {
        bool check = false;
        Map values = value.value;
        if (values != null) {
          values.forEach((key, value) {
            if (value['status'] != "canceled") {
              repeatOrder(Order.toOrder(value));
              check = true;
            }
          });
          if (check) {
            showSnackBar("All orders repeated successfully...!", context);
          } else {
            showSnackBar("There are no orders to repeat...!", context);
          }
        } else {
          showSnackBar("There are no orders to repeat...!", context);
        }
      }
    });
  }

  void restoreAllOrder(BuildContext context) {
    orderReference
        .orderByChild("tableNo")
        .equalTo(table.getTableNo())
        .once()
        .then((value) {
      if (value != null) {
        bool check = false;
        Map values = value.value;
        if (values != null) {
          values.forEach((key, value) {
            if (value['status'] == "canceled") {
              restoreOrder(Order.toOrder(value));
              check = true;
            }
          });
          if (check) {
            showSnackBar("All orders restored successfully...!", context);
          } else {
            showSnackBar("There are no canceled orders...!", context);
          }
        } else {
          showSnackBar("There are no canceled orders...!", context);
        }
      }
    });
  }

  showSaveOrderDialog(Order order) {
    String itemNameDropDownValue1;
    String itemTypeDropDownValue1;
    List itemNameDropDownList1 = [];
    TextEditingController itemQuantityController1 = TextEditingController();
    TextEditingController itemNoteController1 = TextEditingController();
    if (order.getQuantity() != 0) {
      itemQuantityController1.text = order.getQuantity().toString();
    }
    itemNoteController1.text = order.getNote();
    itemReference.once().then((value) {
      if (value != null) {
        Map values = value.value;
        if (values != null) {
          values.forEach((key, value) {
            itemNameDropDownList1.add(value['name']);
          });
          itemNameDropDownValue1 = itemNameDropDownList1[0];
          if (order.itemName != "") {
            itemNameDropDownValue1 = order.itemName;
          }
          if (order.type != "") {
            itemTypeDropDownValue1 = order.type;
          } else {
            itemTypeDropDownValue1 = "Oil";
          }
          showDialog(
              context: context,
              builder: (context) {
                String itemNameDropDownValue = itemNameDropDownValue1;
                String itemTypeDropDownValue = itemTypeDropDownValue1;
                TextEditingController itemQuantityController =
                    itemQuantityController1;
                TextEditingController itemNoteController = itemNoteController1;
                List itemNameDropDownList = itemNameDropDownList1;
                order.setItemName(itemNameDropDownValue);
                order.setType(itemTypeDropDownValue);
                if (order.getQuantity() != 0) {
                  itemQuantityController.text = order.getQuantity().toString();
                }
                itemNoteController.text = order.getNote();

                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                    title: Text("Order Detail"),
                    content: Form(
                      key: _formStateKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text("Item Name: ")),
                              Expanded(
                                child: DropdownButton(
                                  items: itemNameDropDownList.map((value) {
                                    return DropdownMenuItem(
                                        value: value, child: Text(value));
                                  }).toList(),
                                  value: itemNameDropDownValue,
                                  onChanged: (newValue) {
                                    order.setItemName(newValue);
                                    print(order.getItemName());
                                    setState(() {
                                      itemNameDropDownValue = newValue;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 0,
                            height: 0,
                            margin: EdgeInsets.only(bottom: 15.0),
                          ),
                          Row(
                            children: [
                              Expanded(child: Text("Item Type: ")),
                              Expanded(
                                child: DropdownButton(
                                  items: ["Oil", "Butter", "Cheese", "None"]
                                      .map((value) {
                                    return DropdownMenuItem(
                                        value: value, child: Text(value));
                                  }).toList(),
                                  value: itemTypeDropDownValue,
                                  onChanged: (newValue) {
                                    order.setType(newValue);
                                    print(order.getType());
                                    setState(() {
                                      itemTypeDropDownValue = newValue;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 0,
                            height: 0,
                            margin: EdgeInsets.only(bottom: 15.0),
                          ),
                          TextFormField(
                            controller: itemQuantityController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Please Enter Quantity";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                                labelText: "Quantiy",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0))),
                            onChanged: (newQuantity) {
                              if (newQuantity.isNotEmpty) {
                                order.setQuantity(int.parse(newQuantity));
                              }
                              print(order.getQuantity());
                            },
                          ),
                          Container(
                            width: 0,
                            height: 0,
                            margin: EdgeInsets.only(bottom: 15.0),
                          ),
                          TextFormField(
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            controller: itemNoteController,
                            decoration: InputDecoration(
                                labelText: "Note",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0))),
                            onChanged: (newNote) {
                              order.setNote(newNote);
                              print(order.getNote());
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            if (_formStateKey.currentState.validate()) {
                              saveOrder(order);
                              Navigator.pop(context);
                              showSnackBar(
                                  "Order Saved Successfully...!", context);
                            }
                          },
                          child: Text("Save Order"))
                    ],
                  );
                });
              });
        }
      }
    });
  }

  void showSnackBar(String message, BuildContext context) {
    SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
