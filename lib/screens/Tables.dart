import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:order_manager/modal/Table.dart';

import 'HomePage.dart';

class Tables extends StatefulWidget {
  final FirebaseApp app;
  Tables(this.app);

  @override
  _TablesState createState() => _TablesState(app);
}

class _TablesState extends State<Tables> {
  FirebaseApp app;
  _TablesState(this.app);
  FirebaseDatabase database;
  DatabaseReference tableReference;
  List<Table1> tableList = [];
  List tempList = [];

  @override
  void initState() {
    super.initState();
    database = FirebaseDatabase(app: app);
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    tableReference = database.reference().child("tables");
    tableReference.keepSynced(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            tooltip: "Delete Table",
            heroTag: "Delete Button",
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
            onPressed: () {
              removeTable();
            },
            backgroundColor: Colors.red,
          ),
          Container(
            width: 0,
            height: 0,
            margin: EdgeInsets.only(right: 10.0),
          ),
          FloatingActionButton(
            tooltip: "Add Table",
            heroTag: "Add Button",
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              addTable();
            },
            backgroundColor: Colors.red,
          ),
        ],
      ),
      appBar: AppBar(
        leading: GestureDetector(
          child: Icon(Icons.arrow_back),
          onTap: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => HomePage(app)));
          },
        ),
        title: Text("Manage Tables"),
      ),
      body: WillPopScope(
        onWillPop: () {
          return Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomePage(app)));
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

  void addTable() {
    int tableNo = 0;
    Query tableNoQuery = tableReference.orderByChild('tableNo').limitToLast(1);
    tableNoQuery.once().then((value) {
      Map values = value.value;
      if (values == null) {
        tableNo++;
      } else {
        values.forEach((key, value) {
          tableNo = value['tableNo'];
          tableNo++;
        });
      }
      String id = tableReference.push().key;
      Map tableMap = Table1(tableNo, id).toMap();
      tableReference.child(id).set(tableMap);
      updateListView();
      showSnackBar("Table added successfully...", context);
    });
  }

  void removeTable() {
    String tableId;
    int tableNo;
    Query tableNoQuery = tableReference.orderByChild('tableNo').limitToLast(1);
    tableNoQuery.once().then((value) {
      Map values = value.value;
      if (values == null) {
        showSnackBar("No Tables found...", context);
      } else {
        values.forEach((key, value) {
          tableId = key;
          tableNo = value['tableNo'];
        });

        isOrderExists(tableNo).then((value) {
          if (!value) {
            DatabaseReference tableReference1 = tableReference.child(tableId);
            tableReference1.remove();
            updateListView();
            showSnackBar("Table removed successfully...", context);
          } else {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Text("Please clear the table to delete...!"),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("OK"))
                    ],
                  );
                });
          }
        });
      }
    });
  }

  Future<bool> isOrderExists(int tableNo) async {
    DatabaseReference orderReference = database.reference().child("orders");
    List temp = [];
    bool isThereOrder = await orderReference.once().then((value) {
      if (value != null) {
        Map values = value.value;
        if (values != null) {
          values.forEach((key, value) {
            if (value['tableNo'] == tableNo) {
              temp.add(1);
            }
          });
        }
        if (temp.length != 0) {
          return true;
        }
        return false;
      }
      return Future.value(true);
    });

    return isThereOrder;
  }

  updateListView() {
    setState(() {});
  }

  void showSnackBar(String message, BuildContext context) {
    SnackBar snackBar = SnackBar(content: Text(message));
    //Scaffold.of(context).showSnackBar(snackBar);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
