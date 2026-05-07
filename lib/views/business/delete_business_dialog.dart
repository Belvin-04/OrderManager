import 'package:flutter/material.dart';
import 'package:order_manager/models/business.dart';

class DeleteBusinessDialog extends StatelessWidget {
  final Business initialBusiness;
  final Future<void> Function(Business) onDelete;

  const DeleteBusinessDialog({
    super.key,
    required this.initialBusiness,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Business'),
      content: Text(
        'Delete "${initialBusiness.name}" and all its orders, '
        'types, items, and tables?',
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final NavigatorState navigator = Navigator.of(context);
            await onDelete(initialBusiness);
            navigator.pop();
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
