import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/modal/order.dart';
import 'package:order_manager/modal/table.dart';
import 'package:order_manager/screens/home_page.dart';
import 'package:order_manager/screens/tabs/cancelled_orders.dart';
import 'package:order_manager/screens/tabs/completed_orders.dart';
import 'package:order_manager/screens/tabs/pending_orders.dart';
import 'package:order_manager/utils/firebase_service.dart';

import 'bills.dart';

class Orders extends StatefulWidget {
  final Table1 table;
  Orders(this.table);

  @override
  _OrdersState createState() => _OrdersState(table);
}

class _OrdersState extends State<Orders> {

  Table1 table;
  _OrdersState(this.table);
  FirebaseService service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(

        appBar: AppBar(
            leading: GestureDetector(
              child: Icon(Icons.arrow_back),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => HomePage()));
              },
            ),
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
              PopupMenuButton(onSelected: (value) async {
                switch (value) {
                  case "Repeat all":
                    {
                      bool check = await service.repeatAllOrder(table);
                      if(check){
                        service.showSnackBar("All orders repeated successfully...!", context);
                      }
                      else{
                        service.showSnackBar("There are no orders to repeat...!", context);
                      }
                      updateList();
                      break;
                    }
                  case "Restore all":
                    {
                      bool check = await service.restoreAllOrder(table);
                      if(check){
                        service.showSnackBar("All orders restored successfully...!", context);
                      }
                      else{
                        service.showSnackBar("There are no canceled orders...!", context);
                      }
                      updateList();
                      break;
                    }
                  case "Bill":
                    {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Bills(table)));
                      break;
                    }
                }
              }, itemBuilder: (BuildContext context) {
                return ["Repeat all", "Restore all", "Bill"].map((choice) {
                  return PopupMenuItem(
                    child: Text(choice),
                    value: choice,
                  );
                }).toList();
              })
            ]),
        body: WillPopScope(
          onWillPop: () {
            Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>HomePage()));
            return Future.value(true);
          },
          child: TabBarView(
            children: [
              PendingOrders(table: widget.table),
              CompletedOrders(table: widget.table),
              CancelledOrders(table: widget.table)
            ],
          ),
        ),
      ),
    );
  }

  updateList() {
    setState(() {});
  }

}
