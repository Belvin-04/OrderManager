import 'package:flutter/material.dart';
import 'package:order_manager/models/app_user.dart';

class SaveEmployeeDialog extends StatefulWidget {
  final AppUser initialEmployee;
  final Future<void> Function(AppUser) onSave;

  const SaveEmployeeDialog({
    super.key,
    required this.initialEmployee,
    required this.onSave,
  });

  @override
  State<SaveEmployeeDialog> createState() => _SaveEmployeeDialogState();
}

class _SaveEmployeeDialogState extends State<SaveEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late AppUser _editedEmployee;

  @override
  void initState() {
    super.initState();
    _editedEmployee = widget.initialEmployee;
    _nameController = TextEditingController(text: widget.initialEmployee.name);
    _emailController = TextEditingController(
      text: widget.initialEmployee.email,
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
                  _editedEmployee = _editedEmployee.copyWith(name: name);
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
                  if (email.isNotEmpty) {
                    _editedEmployee = _editedEmployee.copyWith(email: email);
                  }
                },
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please Enter Employee Email";
                  }
                  if (!isEmail(value)) {
                    return "Please Enter Valid Email";
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await widget.onSave(_editedEmployee);
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text("Save Employee"),
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
}
