import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/utils/show_dialog_functions.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';
import 'package:order_manager/views/orders/orders.dart';
import 'package:order_manager/views/ui_utils.dart';

enum TablePopupAction { takeOrder, swap, clear }

typedef ClearTableFn =
    Future<void> Function(BuildContext context, WidgetRef ref, Table1 table);

typedef SwapTableFn =
    Future<void> Function(BuildContext context, WidgetRef ref, Table1 table);

ClearTableFn clearTable = _clearTableImpl;
SwapTableFn swapTableOrder = _swapTableOrderImpl;

Future<void> _clearTableImpl(
  BuildContext context,
  WidgetRef ref,
  Table1 table,
) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
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
      showSnackBar("Table is already cleared ...", messenger);
  }
}

Future<void> _swapTableOrderImpl(
  BuildContext context,
  WidgetRef ref,
  Table1 table,
) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final decision = await ref
      .read(tablesViewmodelProvider.notifier)
      .swapTable(table.tableNo.toString());
  if (!context.mounted) return;
  switch (decision.result) {
    case SwapTableResult.noFreeTables:
      showSnackBar("There are no free tables....!", messenger);

    case SwapTableResult.noOrdersOnSource:
      showSnackBar("There are no orders on the table...!", messenger);

    case SwapTableResult.noOrdersAtAll:
      showSnackBar("All tables are free...!", messenger);

    case SwapTableResult.canSwap:
      showSwapDialog(context, ref, table.tableNo, decision.availableTables);
  }
}

void takeOrder(BuildContext context, Table1 table) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => Orders(table)),
  );
}
