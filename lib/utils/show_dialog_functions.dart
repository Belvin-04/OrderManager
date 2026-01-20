import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/tables/table_clear_dialog.dart';
import 'package:order_manager/views/tables/table_clear_warning_dialog.dart';
import 'package:order_manager/views/tables/table_swap_dialog.dart';
import 'package:order_manager/views/ui_utils.dart';

void showClearTableDialog(BuildContext context, WidgetRef ref, Table1 table) {
  showDialog(
    context: context,
    builder: (BuildContext context) => TableClearDialog(
      table: table,
      onClear: (tableKey) async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
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
  final sortedTables = [...availableTables]..sort();
  showDialog(
    context: context,
    builder: (BuildContext context) => TableSwapDialog(
      availableTables: sortedTables,
      onSelect: (targetTableNo) async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
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

void showClearTableWarningDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) => const TableClearWarningDialog(),
  );
}
