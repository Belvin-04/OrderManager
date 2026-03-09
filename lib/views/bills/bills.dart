import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/bills_provider.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/utils/bill_footer.dart';
import 'package:order_manager/utils/bill_item.dart';
import 'package:order_manager/views/bills/bills_split.dart';
import 'package:order_manager/views/bills/split_bill_dialog.dart';
import 'package:order_manager/views/ui_utils.dart';

class Bills extends ConsumerWidget {
  final Table1 table;

  const Bills(this.table, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billState = ref.watch(billOrdersProvider(table.tableNo.toString()));
    double maxHeight = MediaQuery.of(context).size.height - 270;
    return Scaffold(
      appBar: AppBar(
        title: Text("Table ${table.tableNo}: Bill"),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_outlined),
            onPressed: () {
              showSplitBillDialog(context, ref, table);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const Center(child: Text("Invoice", style: TextStyle(fontSize: 30))),
          const Divider(color: Colors.white),
          const BillItem("Name", "Quantity", "Total Price", "Single Price"),
          const Divider(color: Colors.white),
          billState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
            data: (orders) {
              if (orders.isEmpty) {
                return const Center(child: Text("No orders found."));
              }

              return Column(
                children: [
                  Container(
                    height: orders.length * 60,
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final Order order = orders[index];
                        return BillItem(
                          "${order.item.name} ${order.type.getType(0)}",
                          "${order.quantity}",
                          "${order.amount}",
                          "${order.amount / order.quantity}",
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white),
                  BillFooter(table),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void showSplitBillDialog(BuildContext context, WidgetRef ref, Table1 table) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<bool>(
        future: ref
            .read(ordersViewModelProvider.notifier)
            .hasAnyOrdersForTable(table.tableNo.toString(), isSplit: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hasSplitOrders = snapshot.data!;
          return SplitBillDialog(
            table: table,
            onSplit: (int value) {
              if (!hasSplitOrders) {
                ref
                    .read(ordersViewModelProvider.notifier)
                    .createSplitOrders(table.tableNo.toString());
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BillsSplit(table: table, totalSplit: value),
                  ),
                );
              } else {
                Navigator.pop(context);
                showSnackBar(
                  "Someone has already created split orders",
                  ScaffoldMessenger.of(context),
                );
              }
            },
          );
        },
      ),
    );
  }
}
