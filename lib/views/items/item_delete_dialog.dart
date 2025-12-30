import 'package:flutter/material.dart';
import 'package:order_manager/models/item.dart';

class ItemDeleteDialog extends StatelessWidget {
  final Item initialItem;
  final Future<void> Function(Item) onDelete;

  const ItemDeleteDialog({
    super.key,
    required this.initialItem,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Item ?"),
      content: const Text("This action cannot be undone..."),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () async {
            final NavigatorState navigator = Navigator.of(context);
            await onDelete(initialItem);
            navigator.pop();
          },
        ),
      ],
    );
  }
}
