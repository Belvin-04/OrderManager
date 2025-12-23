import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/utils/bill_footer.dart';
import 'package:order_manager/utils/bill_item.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';

class Bills extends ConsumerWidget {
  final Table1 table;

  const Bills(this.table, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billState = ref.watch(
      billOrdersProvider(table.getTableNo().toString()),
    );
    double maxHeight = MediaQuery.of(context).size.height - 270;
    return Scaffold(
      appBar: AppBar(title: Text("Table ${table.getTableNo()}: Bill")),
      body: ListView(
        children: [
          Center(child: Text("Invoice", style: TextStyle(fontSize: 30))),
          Divider(color: Colors.white),
          BillItem("Name", "Quantity", "Total Price", "Single Price"),
          Divider(color: Colors.white),
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
                          "${order.getItemName()} ${order.getType(0)}",
                          "${order.getQuantity()}",
                          "${order.getAmount()}",
                          "${(order.getAmount() / order.getQuantity())}",
                        );
                      },
                    ),
                  ),
                  Divider(color: Colors.white),
                  BillFooter(table),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
