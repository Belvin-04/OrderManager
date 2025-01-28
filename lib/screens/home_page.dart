import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:order_manager/modal/table.dart';
import 'package:order_manager/screens/orders.dart';
import 'package:order_manager/utils/NavigationDrawer.dart' as Drawer;
import 'package:order_manager/utils/firebase_service.dart';

import '../modal/order.dart';

class HomePage extends StatelessWidget {
  final FirebaseService service = FirebaseService();
  final List<Table1> tableList = [];
  final List tempList = [];
  final _scaffoldStateKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldStateKey,
      drawer: Drawer.NavigationDrawer(),
      appBar: AppBar(
        title: Text("Home"),
      ),
      body: WillPopScope(
        onWillPop: () {
          if (_scaffoldStateKey.currentState!.isDrawerOpen) {
            Navigator.pop(context);
          }
          return Future.value(false);
        },
        child: FutureBuilder<DataSnapshot>(
          future: service.tableReference.get(),
          builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
            if (snapshot.hasData) {
              tableList.clear();
              tempList.clear();
              Map values = {};
              if (snapshot.data?.value != null) {
                values = snapshot.data?.value as Map<dynamic,dynamic>;
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
                                            Orders(tableList[index])));
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
                              onTap: () async {
                                int check = await service.swapTable(context,tableList[index].getTableNo(),tableList);
                                if(check == 0){

                                }
                                else if(check == 1){
                                  service.showSnackBar("There are no free tables....!", context);
                                }
                                else if(check == 2){
                                  service.showSnackBar("There are no orders on the table...!", context);
                                }
                                else if(check == 3){
                                  service.showSnackBar("All tables are free...!", context);
                                }
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
                              onTap: () async {
                                int check = await service.clearTable(tableList[index].getTableNo());
                                if(check == 0){
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
                                }
                                else if(check == 1){
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
                                                onPressed: () async {
                                                  List<Order> orders = await service.getAllTableOrders(tableList[index]);
                                                  for(var order in orders){
                                                    service.deleteOrder(order);
                                                  }
                                                  Navigator.pop(context);
                                                  service.showSnackBar("Table cleared Successfully...", context);
                                                },
                                                child: Text("OK"))
                                          ],
                                        );
                                      });
                                }
                                else if(check == 2){
                                  service.showSnackBar("Table is already cleared ...", context);
                                }
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
}
