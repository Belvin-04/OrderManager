import 'package:flutter/material.dart';
import 'package:order_manager/models/table.dart';

class TableClearDialog extends StatelessWidget {
  final Table1 table;
  final Future<void> Function(String) onClear;
  const TableClearDialog({
    super.key,
    required this.onClear,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("WARNING...!"),
      content: const Text(
        "All order details will be lost after clearing the table...!",
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await onClear(table.tableNo.toString());
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}
