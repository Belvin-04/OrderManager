import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/orders/tabs/cancelled_orders.dart';
import 'package:order_manager/views/orders/tabs/completed_orders.dart';
import 'package:order_manager/views/orders/tabs/pending_orders.dart';
import 'package:order_manager/views/ui_utils.dart';

import '../bills.dart';

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
                      bool check = await ref
                          .read(ordersViewModelProvider.notifier)
                          .repeatAllOrders(table);
                      if (check) {
                        if (!context.mounted) return;
                        showSnackBar(
                          "All orders repeated successfully...!",
                          context,
                        );
                      } else {
                        if (!context.mounted) return;
                        showSnackBar(
                          "There are no orders to repeat...!",
                          context,
                        );
                      }
                      break;
                    }
                  case "Restore all":
                    {
                      bool check = await ref
                          .read(ordersViewModelProvider.notifier)
                          .restoreAllOrders(table);
                      if (check) {
                        if (!context.mounted) return;
                        showSnackBar(
                          "All orders restored successfully...!",
                          context,
                        );
                      } else {
                        if (!context.mounted) return;
                        showSnackBar(
                          "There are no canceled orders...!",
                          context,
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
