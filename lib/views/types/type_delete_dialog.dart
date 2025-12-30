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
      title: const Text("Delete Type ?"),
      content: const Text("This action cannot be undone..."),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () async {
            final NavigatorState navigator = Navigator.of(context);
            await onDelete(initialType);
            navigator.pop();
          },
        ),
      ],
    );
  }
}
