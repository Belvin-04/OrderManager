import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';
import 'package:order_manager/views/bills/bills.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/orders/tabs/cancelled_orders.dart';
import 'package:order_manager/views/orders/tabs/completed_orders.dart';
import 'package:order_manager/views/orders/tabs/pending_orders.dart';
import 'package:order_manager/views/ui_utils.dart';

class Orders extends ConsumerWidget {
  final Table1 table;
  const Orders(this.table, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            child: const Icon(Icons.arrow_back),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(child: Text("Pending Orders")),
              Tab(child: Text("Completed Orders")),
              Tab(child: Text("Canceled Orders")),
            ],
          ),
          title: Text("Table ${table.tableNo}: Orders"),
          actions: [
            PopupMenuButton(
              onSelected: (value) async {
                switch (value) {
                  case "Repeat all":
                    {
                      final ScaffoldMessengerState messenger =
                          ScaffoldMessenger.of(context);
                      bool check = await ref
                          .read(ordersViewModelProvider.notifier)
                          .repeatAllOrders(table);
                      if (check) {
                        showSnackBar(
                          "All orders repeated successfully...!",
                          messenger,
                        );
                      } else {
                        showSnackBar(
                          "There are no orders to repeat...!",
                          messenger,
                        );
                      }
                      break;
                    }
                  case "Restore all":
                    {
                      final ScaffoldMessengerState messenger =
                          ScaffoldMessenger.of(context);
                      bool check = await ref
                          .read(ordersViewModelProvider.notifier)
                          .restoreAllOrders(table);
                      if (check) {
                        showSnackBar(
                          "All orders restored successfully...!",
                          messenger,
                        );
                      } else {
                        showSnackBar(
                          "There are no canceled orders...!",
                          messenger,
                        );
                      }
                      break;
                    }
                  case "Bill":
                    {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Bills(table)),
                      );
                      break;
                    }
                }
              },
              itemBuilder: (BuildContext context) {
                return ["Repeat all", "Restore all", "Bill"].map((choice) {
                  return PopupMenuItem(value: choice, child: Text(choice));
                }).toList();
              },
            ),
          ],
        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
          child: TabBarView(
            children: [
              PendingOrders(table: table),
              CompletedOrders(table: table),
              CancelledOrders(table: table),
            ],
          ),
        ),
      ),
    );
  }
}
