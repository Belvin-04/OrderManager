import 'package:flutter/material.dart';
import 'package:order_manager/models/business.dart';

class AddBusinessDialog extends StatefulWidget {
  final Business initalBusiness;
  final Future<void> Function(Business) onSave;
  const AddBusinessDialog({
    super.key,
    required this.initalBusiness,
    required this.onSave,
  });

  @override
  State<AddBusinessDialog> createState() => _AddBusinessDialogState();
}

class _AddBusinessDialogState extends State<AddBusinessDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _controller;
  late Business _editedBusiness;

  @override
  void initState() {
    super.initState();
    _editedBusiness = widget.initalBusiness;
    _controller = TextEditingController(text: _editedBusiness.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Business'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          onChanged: (name) {
            _editedBusiness = _editedBusiness.copyWith(name: name);
          },
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Business name',
            hintText: 'Enter business name',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Business name is required';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final NavigatorState navigator = Navigator.of(context);
            if (_formKey.currentState?.validate() != true) {
              return;
            }
            await widget.onSave(_editedBusiness);
            navigator.pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
