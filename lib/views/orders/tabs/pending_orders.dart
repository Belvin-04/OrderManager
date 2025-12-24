import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';
import 'package:order_manager/views/orders/order_save_dialog.dart';
import 'package:order_manager/views/ui_utils.dart';

class PendingOrders extends ConsumerWidget {
  final Table1 table;

  const PendingOrders({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOrdersState = ref.watch(
      pendingOrdersProvider(table.tableNo.toString()),
    );
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: "Take New Order",
        child: const Icon(Icons.add),
        onPressed: () {
          showSaveOrderDialog(
            context,
            ref,
            Order(
              id: "",
              itemName: "",
              amount: 0,
              type: "",
              tableNo: table.tableNo,
              note: "",
              status: "pending",
              quantity: 0,
            ),
            0,
          );
        },
      ),
      body: pendingOrdersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text("No pending orders"));
          }
          return ListView.builder(
            shrinkWrap: true,
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final Order order = orders[index];
              return Card(
                child: ListTile(
                  title: Text(order.getData()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        child: const Tooltip(
                          message: "Complete Order",
                          child: Icon(Icons.check, color: Colors.green),
                        ),
                        onTap: () async {
                          await ref
                              .read(ordersViewModelProvider.notifier)
                              .completeOrder(order);
                          if (!context.mounted) return;
                          showSnackBar(
                            "Order Completed Successfully...",
                            context,
                          );
                        },
                      ),
                      Container(
                        height: 0,
                        width: 0,
                        margin: const EdgeInsets.only(right: 10.0),
                      ),
                      GestureDetector(
                        child: const Tooltip(
                          message: "Edit Order",
                          child: Icon(Icons.edit, color: Colors.blue),
                        ),
                        onTap: () {
                          showSaveOrderDialog(context, ref, order, 0);
                        },
                      ),
                      Container(
                        height: 0,
                        width: 0,
                        margin: const EdgeInsets.only(right: 10.0),
                      ),
                      GestureDetector(
                        child: const Tooltip(
                          message: "Cancel Order",
                          child: Icon(Icons.cancel, color: Colors.red),
                        ),
                        onTap: () async {
                          await ref
                              .read(ordersViewModelProvider.notifier)
                              .cancelOrder(order);
                          if (!context.mounted) return;
                          showSnackBar(
                            "Order Canceled Successfully...",
                            context,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void showSaveOrderDialog(
    BuildContext context,
    WidgetRef ref,
    Order order,
    int flag,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => OrderSaveDialog(
        initialOrder: order,
        onSave: (editedOrder) async {
          await ref
              .read(ordersViewModelProvider.notifier)
              .saveOrder(editedOrder);
          if (!context.mounted) return;
          showSnackBar("Order Saved Successfully...!", context);
        },
      ),
    );
  }
}
