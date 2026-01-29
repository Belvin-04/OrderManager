import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/bills/split_orders_dialog.dart';
import 'package:order_manager/views/bills/split_tables_dialog.dart';
import 'package:order_manager/views/home_page/total_amount.dart';
import 'package:order_manager/views/ui_utils.dart';

class BillsSplit extends ConsumerWidget {
  final Table1 table;
  final int totalSplit;
  const BillsSplit({super.key, required this.table, required this.totalSplit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitOrdersState = ref.watch(
      splitOrdersProvider(table.tableNo.toString()),
    );
    return Scaffold(
      appBar: AppBar(title: Text("Table No. ${table.tableNo} Bills Split")),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
            context,
          );
          final NavigatorState navigator = Navigator.of(context);
          final bool isSplitOrdersRemoved = await ref
              .read(ordersViewModelProvider.notifier)
              .removeSplitOrdersForTable(table.tableNo.toString());
          if (!isSplitOrdersRemoved) {
            showSnackBar("Problem removing split orders", messenger);
          }
          navigator.pop();
        },
        child: SizedBox(
          height: double.infinity,
          child: Column(
            children: [
              Expanded(
                child: splitOrdersState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const Center(child: Text("No orders"));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        Order order = orders[index];
                        return GestureDetector(
                          onTap: () {
                            showSplitTableDialog(context, ref, order);
                          },
                          child: Card(
                            child: ListTile(
                              title: Text(
                                "${order.item.name} ${order.type.getType(0)}",
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: totalSplit,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: GestureDetector(
                        onTap: () async {
                          final messanger = ScaffoldMessenger.of(context);
                          List<Order> orders = await ref
                              .read(ordersViewModelProvider.notifier)
                              .getOrdersForSplitTable(table.tableNo, index + 1);
                          if (!context.mounted) return;
                          if (orders.isEmpty) {
                            showSnackBar(
                              "No orders on the split table",
                              messanger,
                            );
                          } else {
                            showSplitOrderDialog(context, ref, orders, index);
                          }
                        },
                        child: ListTile(
                          title: Text("Split No. : ${index + 1}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TotalAmount(table: table, splitNo: index + 1),
                              GestureDetector(
                                child: const Tooltip(
                                  message: "Clear Split Orders",
                                  child: Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.red,
                                  ),
                                ),
                                onTap: () async {
                                  await ref
                                      .read(ordersViewModelProvider.notifier)
                                      .resetSplitNo(
                                        table.tableNo.toString(),
                                        (index + 1).toString(),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSplitTableDialog(BuildContext context, WidgetRef ref, Order order) {
    showDialog(
      context: context,
      builder: (context) {
        return SplitTablesDialog(
          totalSplit: totalSplit,
          onTap: (int splitNo) {
            ref
                .read(ordersViewModelProvider.notifier)
                .changeOrderSplitNo(order, splitNo);
          },
        );
      },
    );
  }

  void showSplitOrderDialog(
    BuildContext context,
    WidgetRef ref,
    List<Order> orders,
    int splitNo,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return SplitOrdersDialog(
          orders: orders,
          onSelect: (Order order) {
            ref
                .read(ordersViewModelProvider.notifier)
                .changeOrderSplitNo(order, 0);
          },
        );
      },
    );
  }
}
