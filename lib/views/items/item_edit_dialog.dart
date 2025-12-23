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

  @override
  void initState() {
    super.initState();
    _editedItem = widget.initialItem;
    _itemNameController = TextEditingController(
      text: widget.initialItem.getName(),
    );
    _itemPriceController = TextEditingController(
      text: widget.initialItem.getPrice() == 0
          ? ''
          : widget.initialItem.getPrice().toString(),
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
      title: Text("Item Detail"),
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
                margin: EdgeInsets.only(bottom: 10.0),
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await widget.onSave(_editedItem);
              if (!context.mounted) return;
              Navigator.pop(context);
            }
          },
          child: Text("Save Item"),
        ),
      ],
    );
  }
}
