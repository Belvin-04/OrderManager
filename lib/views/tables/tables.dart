import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';
import 'package:order_manager/views/tables/tables_warning_dialog.dart';
import 'package:order_manager/views/ui_utils.dart';

import '../home_page/home_page.dart';

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
              RemoveTableResult result = await ref
                  .read(tablesViewmodelProvider.notifier)
                  .removeTable();
              if (!context.mounted) return;
              switch (result) {
                case RemoveTableResult.noTables:
                  showSnackBar("No Tables found...", context);
                case RemoveTableResult.hasOrders:
                  showWarningDialog(context);
                case RemoveTableResult.removed:
                  showSnackBar("Table removed successfully...", context);
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
              await ref.read(tablesViewmodelProvider.notifier).addTable();
              if (!context.mounted) return;
              showSnackBar("Table added successfully...", context);
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      appBar: AppBar(
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        title: const Text("Manage Tables"),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
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
                  child: ListTile(title: Text("Table No. : ${table.tableNo}")),
                );
              },
            );
          },
        ),
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
