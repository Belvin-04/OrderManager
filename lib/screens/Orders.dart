import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/modal/Order.dart';
import 'package:order_manager/modal/Table.dart';

import 'HomePage.dart';

class Orders extends StatefulWidget {
  final Table_1 table;
  Orders(this.table);

  @override
  _OrdersState createState() => _OrdersState(table);
}

class _OrdersState extends State<Orders> {
  final _formStateKey = GlobalKey<FormState>();
  Table_1 table;
  _OrdersState(this.table);
  DatabaseReference orderReference =
      FirebaseDatabase.instance.reference().child("orders");
  DatabaseReference itemReference =
      FirebaseDatabase.instance.reference().child("items");
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            showSaveOrderDialog(
                Order(0, "", "", table.geTableNo(), "", "pending", ""));
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
          title: Text("Table ${table.geTableNo()}: Orders"),
        ),
        body: WillPopScope(
          onWillPop: () {
            Navigator.pop(context);
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
            .equalTo(table.geTableNo())
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
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(orderList[index].getData()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
                        Container(
                          height: 0,
                          width: 0,
                          margin: EdgeInsets.only(right: 10.0),
                        ),
                        Icon(
                          Icons.edit,
                          color: Colors.blue,
                        ),
                        Container(
                          height: 0,
                          width: 0,
                          margin: EdgeInsets.only(right: 10.0),
                        ),
                        Icon(
                          Icons.cancel,
                          color: Colors.red,
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
                if (value['tableNo'] == table.geTableNo()) {
                  orderList.add(Order.toOrder(value));
                }
              });
            }
            return ListView.builder(
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(orderList[index].getData()),
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
                if (value['tableNo'] == table.geTableNo()) {
                  orderList.add(Order.toOrder(value));
                }
              });
            }
            return ListView.builder(
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(orderList[index].getData()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restore,
                          color: Colors.green,
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

  void saveOrder(Order order) {
    /*orderReference.orderByChild("itemName").equalTo(order.getItemName()).once().then((value) {
      String id = order.getId();
      if(id.isEmpty){
        id = orderReference.push().key;
      }
      else{
        id = order.getId();
      }
      Map orderMap = order.toMap();
      orderMap['id'] = id;

      if(value != null){
        Map values = value.value;
        if(values != null){
          values.forEach((key, value) {
            orderMap['id'] = value['id'];
            orderMap['quantity'] = orderMap['quantity']+value['quantity'];
          });
        }
        orderReference.child(orderMap['id']).set(orderMap);
        updateList();
      }

    });*/
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

  showSaveOrderDialog(Order order) {
    String itemNameDropDownValue1;
    List itemNameDropDownList1 = List();
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
          showDialog(
              context: context,
              builder: (context) {
                String itemNameDropDownValue = itemNameDropDownValue1;
                String itemTypeDropDownValue = "Oil";
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
                                  items:
                                      ["Oil", "Butter", "Cheese"].map((value) {
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
                              setState() {
                                itemQuantityController.text = "";
                                itemNoteController.text = "";
                              }

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
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }
}
