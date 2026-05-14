import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/providers/employee_provider.dart';

class SaveEmployeeDialog extends ConsumerStatefulWidget {
  final BusinessEmployee initialEmployee;
  final Future<void> Function(BusinessEmployee) onSave;

  const SaveEmployeeDialog({
    super.key,
    required this.initialEmployee,
    required this.onSave,
  });

  @override
  ConsumerState<SaveEmployeeDialog> createState() => _SaveEmployeeDialogState();
}

class _SaveEmployeeDialogState extends ConsumerState<SaveEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late BusinessEmployee _editedEmployee;

  String? _emailError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editedEmployee = widget.initialEmployee;
    _nameController = TextEditingController(
      text: widget.initialEmployee.employeeName,
    );
    _emailController = TextEditingController(
      text: widget.initialEmployee.employeeEmail,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Employee Detail"),
      content: SizedBox(
        width: 200,
        height: 130,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                onChanged: (name) {
                  _editedEmployee = _editedEmployee.copyWith(
                    employeeName: name,
                  );
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please Enter Employee Name";
                  }

                  return null;
                },
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Employee Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              Container(
                width: 0.0,
                height: 0.0,
                margin: const EdgeInsets.only(bottom: 10.0),
              ),
              TextFormField(
                onChanged: (email) {
                  _editedEmployee = _editedEmployee.copyWith(
                    employeeEmail: email,
                  );
                },
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please Enter Employee Email";
                  }
                  if (!isEmail(value)) {
                    return "Please Enter Valid Email";
                  }
                  if (_emailError != null) {
                    return _emailError;
                  }
                  return null;
                },
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Employee Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () => _saveEmployee(context, _editedEmployee),
          child: _isSaving
              ? const CircularProgressIndicator()
              : const Text("Save Employee"),
        ),
      ],
    );
  }

  bool isEmail(String value) {
    const pattern =
        r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);

    return regex.hasMatch(value);
  }

  Future<void> _saveEmployee(
    BuildContext context,
    BusinessEmployee editedEmployee,
  ) async {
    setState(() {
      _emailError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final appUser = await ref
        .read(employeeViewModelProvider.notifier)
        .queryAppUserByEmail(editedEmployee.employeeEmail);

    if (appUser == null) {
      setState(() {
        _emailError = "User doesn't exist";
        _isSaving = false;
      });

      _formKey.currentState!.validate();
      return;
    }

    final employeeExists = await ref
        .read(employeeViewModelProvider.notifier)
        .doesEmployeeExists(
          editedEmployee.employeeEmail,
          editedEmployee.businessId,
        );

    if (employeeExists) {
      if (editedEmployee.relationId.isEmpty) {
        setState(() {
          _emailError = "Employee already exists";
          _isSaving = false;
        });

        _formKey.currentState!.validate();
        return;
      } else {
        final user = await ref
            .read(employeeViewModelProvider.notifier)
            .queryBusinessEmployeeByEmail(
              editedEmployee.employeeEmail,
              editedEmployee.businessId,
            );

        if (editedEmployee.relationId != user!.relationId) {
          setState(() {
            _emailError = "Email already exists";
            _isSaving = false;
          });

          _formKey.currentState!.validate();
          return;
        }
      }
    }

    await widget.onSave(editedEmployee);

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
