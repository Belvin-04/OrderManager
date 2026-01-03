import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/utils/navigation_drawer.dart' as drawer;
import 'package:order_manager/viewmodels/tables_viewmodel.dart';
import 'package:order_manager/views/home_page/total_amount.dart';
import 'package:order_manager/views/orders/orders.dart';
import 'package:order_manager/views/tables/table_clear_dialog.dart';
import 'package:order_manager/views/tables/table_clear_warning_dialog.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/tables/table_swap_dialog.dart';
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
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_scaffoldStateKey.currentState!.isDrawerOpen) {
            Navigator.pop(context);
          }
        },
        child: tableState.when(
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
                return Card(
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
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Orders(table),
                              ),
                            );
                          },
                        ),
                        Container(margin: const EdgeInsets.only(right: 10.0)),
                        GestureDetector(
                          child: const Tooltip(
                            message: "Swap Table Order",
                            child: Icon(Icons.swap_vert, color: Colors.yellow),
                          ),
                          onTap: () async {
                            final ScaffoldMessengerState messenger =
                                ScaffoldMessenger.of(context);
                            final decision = await ref
                                .read(tablesViewmodelProvider.notifier)
                                .swapTable(table.tableNo.toString());
                            if (!context.mounted) return;
                            switch (decision.result) {
                              case SwapTableResult.noFreeTables:
                                showSnackBar(
                                  "There are no free tables....!",
                                  messenger,
                                );

                              case SwapTableResult.noOrdersOnSource:
                                showSnackBar(
                                  "There are no orders on the table...!",
                                  messenger,
                                );

                              case SwapTableResult.noOrdersAtAll:
                                showSnackBar(
                                  "All tables are free...!",
                                  messenger,
                                );

                              case SwapTableResult.canSwap:
                                showSwapDialog(
                                  context,
                                  ref,
                                  table.tableNo,
                                  decision.availableTables,
                                );
                            }
                          },
                        ),

                        Container(margin: const EdgeInsets.only(right: 10.0)),
                        GestureDetector(
                          child: const Tooltip(
                            message: "Clear Table",
                            child: Icon(Icons.clear, color: Colors.blue),
                          ),
                          onTap: () async {
                            final ScaffoldMessengerState messenger =
                                ScaffoldMessenger.of(context);
                            ClearTableResult result = await ref
                                .read(tablesViewmodelProvider.notifier)
                                .clearTable(table.tableNo.toString());
                            if (!context.mounted) return;
                            switch (result) {
                              case ClearTableResult.hasPendingOrders:
                                showClearTableWarningDialog(context);
                              case ClearTableResult.canClear:
                                showClearTableDialog(context, ref, table);
                              case ClearTableResult.alreadyCleared:
                                showSnackBar(
                                  "Table is already cleared ...",
                                  messenger,
                                );
                            }
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
      ),
    );
  }

  void showClearTableWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const TableClearWarningDialog(),
    );
  }

  void showClearTableDialog(BuildContext context, WidgetRef ref, Table1 table) {
    showDialog(
      context: context,
      builder: (BuildContext context) => TableClearDialog(
        table: table,
        onClear: (tableKey) async {
          final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
            context,
          );
          await ref
              .read(tablesViewmodelProvider.notifier)
              .clearTableConfirm(tableKey);
          showSnackBar("Table cleared Successfully...", messenger);
        },
      ),
    );
  }

  void showSwapDialog(
    BuildContext context,
    WidgetRef ref,
    int sourceTable,
    List<int> availableTables,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => TableSwapDialog(
        availableTables: availableTables,
        onSelect: (targetTableNo) async {
          final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
            context,
          );
          await ref
              .read(tablesViewmodelProvider.notifier)
              .confirmSwap(
                fromTableKey: sourceTable.toString(),
                toTableKey: targetTableNo.toString(),
              );
          showSnackBar(
            """Orders swapped from Table : $sourceTable to Table : $targetTableNo""",
            messenger,
          );
        },
      ),
    );
  }
}
