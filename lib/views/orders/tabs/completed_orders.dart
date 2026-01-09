import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/ui_utils.dart';

class CompletedOrders extends ConsumerWidget {
  final Table1 table;
  const CompletedOrders({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedOrdersState = ref.watch(
      completedOrdersProvider(table.tableNo.toString()),
    );
    return Scaffold(
      body: completedOrdersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(child: Text("Error: $e")),

        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text("No completed orders"));
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
                          message: "Repeat Order",
                          child: Icon(
                            Icons.replay_rounded,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () async {
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);
                          await ref
                              .read(ordersViewModelProvider.notifier)
                              .repeatOrder(order);
                          showSnackBar(
                            "Order Repeated Successfully...",
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
