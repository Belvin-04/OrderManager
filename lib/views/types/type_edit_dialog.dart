import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/models/type.dart';

class TypeEditDialog extends StatefulWidget {
  final Type1 initialType;
  final Future<void> Function(Type1) onSave;

  const TypeEditDialog({
    super.key,
    required this.initialType,
    required this.onSave,
  });

  @override
  State<TypeEditDialog> createState() => _TypeEditDialogState();
}

class _TypeEditDialogState extends State<TypeEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _typeNameController;
  late TextEditingController _typePriceController;
  late Type1 _editedType;

  @override
  void initState() {
    super.initState();
    _editedType = widget.initialType;
    _typeNameController = TextEditingController(text: widget.initialType.type);
    _typePriceController = TextEditingController(
      text: widget.initialType.price == 0
          ? ''
          : widget.initialType.price.toString(),
    );
  }

  @override
  void dispose() {
    _typeNameController.dispose();
    _typePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Type Detail"),
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
                  _editedType = _editedType.copyWith(type: name);
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please Enter Type";
                  }

                  return null;
                },
                controller: _typeNameController,
                decoration: InputDecoration(
                  labelText: "Type Name",
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
                onChanged: (price) {
                  if (price.isNotEmpty) {
                    _editedType = _editedType.copyWith(price: int.parse(price));
                  }
                },
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please Enter Type Price";
                  }
                  return null;
                },
                controller: _typePriceController,
                decoration: InputDecoration(
                  labelText: "Type Price",
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
              await widget.onSave(_editedType);
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text("Save Type"),
        ),
      ],
    );
  }
}
