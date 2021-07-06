import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:order_manager/modal/Order.dart';
import 'package:order_manager/modal/Table.dart';
import 'package:order_manager/utils/BillItem.dart';

class Bills extends StatefulWidget {
  final Table1 table;
  final FirebaseApp app;
  Bills(this.table, this.app);

  @override
  _BillsState createState() => _BillsState(table, app);
}

class _BillsState extends State<Bills> {
  final Table1 table;
  final FirebaseApp app;
  _BillsState(this.table, this.app);

  FirebaseDatabase database;
  DatabaseReference orderReference;
  DatabaseReference typeReference;
  DatabaseReference itemReference;
  List<Order> orderList = [];
  Map typeMap = Map();
  Map itemMap = Map();

  @override
  void initState() {
    super.initState();
    database = FirebaseDatabase(app: app);
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    orderReference = database.reference().child("orders");
    typeReference = database.reference().child("types");
    itemReference = database.reference().child("items");
    orderReference.keepSynced(true);
    typeReference.keepSynced(true);
    itemReference.keepSynced(true);
    orderReference
        .orderByChild("tableNo")
        .equalTo(table.getTableNo())
        .once()
        .then((value) {
      if (value != null) {
        List<Order> orderList = [];
        Map values = value.value;
        if (values != null) {
          values.forEach((key, value) {
            if (value['status'] != "canceled") {
              orderList.add(Order.toOrder(value));
            }
          });
          setState(() {
            this.orderList = orderList;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Table ${table.getTableNo()}: Bill"),
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.pop(context);
          return Future.value(true);
        },
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
              child: Text(
                "Invoice",
                style: TextStyle(fontSize: 30),
              ),
            ),
            Divider(
              color: Colors.white,
            ),
            BillItem("Name", "Quantity", "Total Price", "Single Price"),
            Divider(
              color: Colors.white,
            ),
            ListView.builder(
                shrinkWrap: true,
                itemCount: orderList.length,
                itemBuilder: (context, index) {
                  return BillItem(
                      "${orderList[index].getItemName()} ${orderList[index].getType(0)}",
                      "${orderList[index].getQuantity()}",
                      "${orderList[index].getAmount()}",
                      "${(orderList[index].getAmount() / orderList[index].getQuantity())}");
                }),
            Divider(
              color: Colors.white,
            ),
            BillFooter(orderList)
          ],
        ),
      ),
    );
  }
}

class BillFooter extends StatelessWidget {
  final List orderList;
  BillFooter(this.orderList);
  @override
  Widget build(BuildContext context) {
    int totalAmount = 0;
    int totalQuantity = 0;
    orderList.forEach((element) {
      totalAmount += element.getAmount();
      totalQuantity += element.getQuantity();
    });
    return BillItem("", "$totalQuantity", "$totalAmount", "");
  }
}
