import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:order_manager/modal/table.dart';
import 'package:order_manager/utils/firebase_service.dart';

import 'home_page.dart';

class Tables extends StatefulWidget {
  @override
  _TablesState createState() => _TablesState();
}

class _TablesState extends State<Tables> {
  List<Table1> tableList = [];
  List tempList = [];
  FirebaseService service = FirebaseService();

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
            onPressed: () async {
              int check = await service.removeTable();
              if (check == 0) {
                service.showSnackBar("No Tables found...", context);
              } else if (check == 1) {
                service.showSnackBar("Table removed successfully...", context);
              } else if (check == 2) {
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
              updateListView();
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
            onPressed: () async {
              await service.addTable();
              service.showSnackBar("Table added successfully...", context);
              updateListView();
            },
            backgroundColor: Colors.red,
          ),
        ],
      ),
      appBar: AppBar(
        leading: GestureDetector(
          child: Icon(Icons.arrow_back),
          onTap: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
        title: Text("Manage Tables"),
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomePage()));
          return Future.value(true);
        },
        child: FutureBuilder<DatabaseEvent>(
          future: service.tableReference.once(),
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.data?.snapshot.value != null) {
              tableList.clear();
              tempList.clear();
              Map values =
                  snapshot.data?.snapshot.value as Map<dynamic, dynamic>;
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

  updateListView() {
    setState(() {});
  }
}
