import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/utils/navigation_drawer.dart' as drawer;
import 'package:order_manager/utils/tap_functions.dart';
import 'package:order_manager/views/home_page/total_amount.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/ui_utils.dart';

class HomePage extends ConsumerWidget {
  final _scaffoldStateKey = GlobalKey<ScaffoldState>();

  HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableState = ref.watch(tablesProvider);
    return Scaffold(
      key: _scaffoldStateKey,
      drawer: const drawer.NavigationDrawer(),
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          GestureDetector(
            child: const Tooltip(
              message: "Table Layout Screen",
              child: Icon(Icons.design_services),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TableLayoutScreen()),
              );
            },
          ),
        ],
      ),
      body: tableState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (tables) {
          if (tables.isEmpty) {
            return const Center(child: Text("No Items"));
          }
          final sortedTables = [...tables]
            ..sort((a, b) => a.tableNo.compareTo(b.tableNo));

          return ListView.builder(
            itemCount: sortedTables.length,
            itemBuilder: (BuildContext context, int index) {
              final Table1 table = sortedTables[index];
              final tableOrderStatusState = ref.watch(
                tableOrderStatus(table.tableNo.toString()),
              );

              return tableOrderStatusState.when(
                loading: () =>
                    const Card(child: ListTile(title: Text("Loading..."))),
                error: (e, _) =>
                    const Card(child: ListTile(title: Text("Error"))),

                data: (data) {
                  final bgColor = getBackgroundColor(data);
                  return Card(
                    color: bgColor,
                    child: ListTile(
                      title: Text("Table No. : ${table.tableNo}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TotalAmount(table: table),
                          GestureDetector(
                            child: const Tooltip(
                              message: "Take Order",
                              child: Icon(
                                Icons.event_note_outlined,
                                color: Colors.green,
                              ),
                            ),
                            onTap: () {
                              takeOrder(context, table);
                            },
                          ),
                          Container(margin: const EdgeInsets.only(right: 10.0)),
                          GestureDetector(
                            child: const Tooltip(
                              message: "Swap Table Order",
                              child: Icon(
                                Icons.swap_vert,
                                color: Colors.yellow,
                              ),
                            ),
                            onTap: () async {
                              await swapTableOrder(context, ref, table);
                            },
                          ),

                          Container(margin: const EdgeInsets.only(right: 10.0)),
                          GestureDetector(
                            child: const Tooltip(
                              message: "Clear Table",
                              child: Icon(Icons.clear, color: Colors.blue),
                            ),
                            onTap: () async {
                              await clearTable(context, ref, table);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
