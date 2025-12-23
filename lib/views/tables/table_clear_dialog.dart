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
      title: Text("WARNING...!"),
      content: Text(
        "All order details will be lost after clearing the table...!",
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await onClear(table.getTableNo().toString());
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: Text("OK"),
        ),
      ],
    );
  }
}
