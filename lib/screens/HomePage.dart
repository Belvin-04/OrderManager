import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:order_manager/modal/Table.dart';
import 'package:order_manager/screens/Orders.dart';
import 'package:order_manager/utils/NavigationDrawer.dart';

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
                        title:
                            Text("Table No. : ${tableList[index].geTableNo()}"),
                        trailing: GestureDetector(
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
}
