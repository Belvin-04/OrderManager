import 'package:flutter/material.dart';
import 'package:order_manager/models/business_employee.dart';

class EmployeeDeleteDialog extends StatelessWidget {
  final BusinessEmployee initialEmployee;
  final Future<void> Function(BusinessEmployee) onDelete;

  const EmployeeDeleteDialog({
    super.key,
    required this.initialEmployee,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Employee ?"),
      content: const Text("This action cannot be undone..."),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () async {
            final NavigatorState navigator = Navigator.of(context);
            await onDelete(initialEmployee);
            navigator.pop();
          },
        ),
      ],
    );
  }
}
