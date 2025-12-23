import 'package:flutter/material.dart';
import 'package:order_manager/models/type.dart';

class TypeDeleteDialog extends StatelessWidget {
  final Type1 initialType;
  final Future<void> Function(Type1) onDelete;

  const TypeDeleteDialog({
    super.key,
    required this.initialType,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Delete Type ?"),
      content: Text("This action cannot be undone..."),
      actions: [
        TextButton(
          child: Text("OK"),
          onPressed: () async {
            await onDelete(initialType);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
