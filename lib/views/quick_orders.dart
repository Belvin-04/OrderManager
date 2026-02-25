import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/orders/order_save_dialog.dart';
import 'package:order_manager/views/ui_utils.dart';

class QuickOrders extends ConsumerWidget {
  const QuickOrders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickOrdersState = ref.watch(quickOrdersProvider);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: "Create New Quick Order",
        child: const Icon(Icons.add),
        onPressed: () {
          showSaveOrderDialog(
            context,
            ref,
            Order(
              id: "",
              item: Item(name: "", price: 0, id: ""),
              amount: 0,
              type: Type1(type: "", price: 0, id: ""),
              table: Table1(tableNo: 0, id: "0"),
              note: "",
              status: "pending",
              quantity: 0,
            ),
            0,
          );
        },
      ),
      appBar: AppBar(title: const Text("Quick Orders")),
      body: quickOrdersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text("No quick orders"));
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
                          message: "Remove Quick Order",
                          child: Icon(Icons.cancel, color: Colors.red),
                        ),
                        onTap: () async {
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);
                          await ref
                              .read(ordersViewModelProvider.notifier)
                              .deleteOrder(order);
                          showSnackBar(
                            "Quick Order Deleted Successfully...",
                            messenger,
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
          final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
            context,
          );
          await ref
              .read(ordersViewModelProvider.notifier)
              .saveOrder(editedOrder);
          showSnackBar("Quick Order Created Successfully...!", messenger);
        },
      ),
    );
  }
}
