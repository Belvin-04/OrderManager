import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';
import 'package:order_manager/views/tables/tables_warning_dialog.dart';
import 'package:order_manager/views/ui_utils.dart';

class Tables extends ConsumerWidget {
  const Tables({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableState = ref.watch(tablesProvider);
    return Scaffold(
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            tooltip: "Delete Table",
            heroTag: "Delete Button",
            onPressed: () async {
              final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                context,
              );
              final dialogContext = context;
              RemoveTableResult result = await ref
                  .read(tablesViewmodelProvider.notifier)
                  .removeTable();
              if (!context.mounted) return;
              switch (result) {
                case RemoveTableResult.noTables:
                  showSnackBar("No Tables found...", messenger);
                case RemoveTableResult.hasOrders:
                  showWarningDialog(dialogContext);
                case RemoveTableResult.removed:
                  showSnackBar("Table removed successfully...", messenger);
              }
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          Container(
            width: 0,
            height: 0,
            margin: const EdgeInsets.only(right: 10.0),
          ),
          FloatingActionButton(
            tooltip: "Add Table",
            heroTag: "Add Button",
            onPressed: () async {
              final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                context,
              );
              await ref.read(tablesViewmodelProvider.notifier).addTable();
              showSnackBar("Table added successfully...", messenger);
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      appBar: AppBar(title: const Text("Manage Tables")),
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
              return Card(
                child: ListTile(title: Text("Table No. : ${table.tableNo}")),
              );
            },
          );
        },
      ),
    );
  }

  void showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const TablesWarningDialog(),
    );
  }
}
