import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:order_manager/modal/Order.dart';
import 'package:order_manager/modal/Table.dart';
import 'package:order_manager/screens/Orders.dart';
import 'package:order_manager/utils/NavigationDrawer.dart';
import 'package:order_manager/utils/ThemeProvider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final FirebaseApp app;
  final List<Table1> tableList = [];
  final List tempList = [];
  final _scaffoldStateKey = GlobalKey<ScaffoldState>();
  HomePage(this.app);
  @override
  Widget build(BuildContext context) {
    FirebaseDatabase database;
    database = FirebaseDatabase(app: app);
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    final DatabaseReference tableReference =
        database.reference().child("tables");
    tableReference.keepSynced(true);

    final DatabaseReference orderReference =
        database.reference().child("orders");
    orderReference.keepSynced(true);

    return Scaffold(
      key: _scaffoldStateKey,
      drawer: NavigationDrawer(app),
      appBar: AppBar(
        title: Text("Home"),
      ),
      body: WillPopScope(
        onWillPop: () {
          if (_scaffoldStateKey.currentState.isDrawerOpen) {
            Navigator.pop(context);
          }
          return Future.value(false);
        },
        child: FutureBuilder(
          future: tableReference.once(),
          builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
            if (snapshot.hasData) {
              tableList.clear();
              tempList.clear();
              Map values = snapshot.data.value;
              if (values != null) {
                values.forEach((key, value) {
                  tempList.add(Table1.toTable(value));
                });

                for (int i = 0; i < tempList.length; i++) {
                  tableList.add(Table1(0, ""));
                }

                values.forEach((key, value) {
                  tableList[value['tableNo'] - 1] = Table1.toTable(value);
                  //tableList.add(Table_1.toTable(value));
                });
              }

              return ListView.builder(
                  itemCount: tableList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: ListTile(
                        title: Text(
                            "Table No. : ${tableList[index].getTableNo()}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              child: Tooltip(
                                message: "Take Order",
                                child: Icon(Icons.event_note_outlined,
                                    color: Colors.green),
                              ),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            Orders(tableList[index], app)));
                              },
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 10.0),
                            ),
                            GestureDetector(
                              child: Tooltip(
                                message: "Swap Table Order",
                                child:
                                    Icon(Icons.swap_vert, color: Colors.yellow),
                              ),
                              onTap: () {
                                swapTable(tableList[index].getTableNo(),
                                    context, orderReference);
                              },
                            ),
                            Container(
                              margin: EdgeInsets.only(right: 10.0),
                            ),
                            GestureDetector(
                              child: Tooltip(
                                message: "Clear Table",
                                child: Icon(Icons.clear, color: Colors.blue),
                              ),
                              onTap: () {
                                clearTable(tableList[index].getTableNo(),
                                    context, orderReference);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  });
            }
            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void deleteOrder(Order order, DatabaseReference orderReference) {
    orderReference.child(order.getId()).remove();
  }

  void saveOrder(Order order, DatabaseReference orderReference) {
    Map orderMap = order.toMap();
    orderReference.child(orderMap['id']).set(orderMap);
  }

  void swapTable(
      int tableNo, BuildContext context, DatabaseReference orderReference) {
    List<int> totalTables = [];
    List<Order> orderList = [];
    Set selectedTableOrderCheckSet = Set();
    tableList.forEach((element) {
      totalTables.add(element.getTableNo());
    });
    Set occupiedTables = Set();
    orderReference.once().then((value) {
      if (value != null) {
        Map values = value.value;
        if (values != null) {
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
                                  title:
                                      Text("Table No. : ${totalTables[index]}"),
                                  onTap: () {
                                    orderList.forEach((element) {
                                      element.setTableNo(totalTables[index]);
                                      saveOrder(element, orderReference);
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
            } else {
              showSnackBar("There are no free tables....!", context);
            }
          } else {
            showSnackBar("There are no orders on the table...!", context);
          }
        } else {
          showSnackBar("All tables are free...!", context);
        }
      }
    });
  }

  void clearTable(
      int tableNo, BuildContext context, DatabaseReference orderReference) {
    orderReference
        .orderByChild("tableNo")
        .equalTo(tableNo)
        .once()
        .then((value) {
      if (value != null) {
        Map values = value.value;
        List temp = [];
        if (values != null) {
          values.forEach((key, value) {
            if (value["status"] == "pending") {
              temp.add(1);
            }
          });
          if (temp.length != 0) {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Text(
                        "Table cannot be cleared if there are pending orders...!"),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("OK"))
                    ],
                  );
                });
          } else {
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("WARNING...!"),
                    content: Text(
                        "All order details will be lost after clearing the table...!"),
                    actions: [
                      TextButton(
                          onPressed: () {
                            values.forEach((key, value) {
                              deleteOrder(Order.toOrder(value), orderReference);
                            });
                            Navigator.pop(context);
                            showSnackBar(
                                "Table cleared Successfully...", context);
                          },
                          child: Text("OK"))
                    ],
                  );
                });
          }
        } else {
          showSnackBar("Table is already cleared ...", context);
        }
      }
    });
  }

  void showSnackBar(String message, BuildContext context) {
    SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
