import 'package:flutter/material.dart';

class TableClearWarningDialog extends StatelessWidget {
  const TableClearWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text("Table cannot be cleared if there are pending orders...!"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("OK"),
        ),
      ],
    );
  }
}
