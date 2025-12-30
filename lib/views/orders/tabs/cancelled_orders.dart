import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';
import 'package:order_manager/views/ui_utils.dart';

class CancelledOrders extends ConsumerWidget {
  final Table1 table;
  const CancelledOrders({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cancelledOrdersState = ref.watch(
      cancelledOrdersProvider(table.tableNo.toString()),
    );
    return Scaffold(
      body: cancelledOrdersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(child: Text("Error: $e")),

        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text("No cancelled orders"));
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
                          message: "Restore Order",
                          child: Icon(Icons.restore, color: Colors.green),
                        ),
                        onTap: () async {
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);
                          await ref
                              .read(ordersViewModelProvider.notifier)
                              .restoreOrder(order);
                          showSnackBar(
                            "Order Restored Successfully...",
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
}
