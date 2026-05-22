import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/models/item.dart';

class ItemEditDialog extends StatefulWidget {
  final Item initialItem;
  final Future<void> Function(Item) onSave;

  const ItemEditDialog({
    super.key,
    required this.initialItem,
    required this.onSave,
  });

  @override
  State<ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<ItemEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _itemNameController;
  late TextEditingController _itemPriceController;
  late Item _editedItem;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _editedItem = widget.initialItem;
    _itemNameController = TextEditingController(text: widget.initialItem.name);
    _itemPriceController = TextEditingController(
      text: widget.initialItem.price == 0
          ? ''
          : widget.initialItem.price.toString(),
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Item Detail"),
      content: SizedBox(
        width: 200,
        height: 150,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                onChanged: (name) {
                  _editedItem = _editedItem.copyWith(name: name);
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please Enter Product Name";
                  }

                  return null;
                },
                controller: _itemNameController,
                decoration: InputDecoration(
                  labelText: "Item Name",
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
                    _editedItem = _editedItem.copyWith(price: int.parse(price));
                  }
                },
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please Enter Product Price";
                  }
                  return null;
                },
                controller: _itemPriceController,
                decoration: InputDecoration(
                  labelText: "Item Price",
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
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      await widget.onSave(_editedItem);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Save Item"),
        ),
      ],
    );
  }
}
