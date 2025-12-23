import 'package:flutter/material.dart';

class TablesWarningDialog extends StatelessWidget {
  const TablesWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text("Please clear the table to delete...!"),
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
