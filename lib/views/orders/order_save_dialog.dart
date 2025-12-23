import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/viewmodels/items_viewmodel.dart';
import 'package:order_manager/viewmodels/types_viewmodel.dart';

class OrderSaveDialog extends ConsumerStatefulWidget {
  final Order initialOrder;
  final Future<void> Function(Order) onSave;

  const OrderSaveDialog({
    super.key,
    required this.initialOrder,
    required this.onSave,
  });

  @override
  ConsumerState<OrderSaveDialog> createState() => _OrderSaveDialogState();
}

class _OrderSaveDialogState extends ConsumerState<OrderSaveDialog> {
  final _formStateKey = GlobalKey<FormState>();
  late Order editedOrder;

  late TextEditingController itemQuantityController;
  late TextEditingController itemNoteController;

  @override
  void initState() {
    super.initState();

    editedOrder = widget.initialOrder;

    itemQuantityController = TextEditingController(
      text: editedOrder.quantity == 0 ? '' : editedOrder.quantity.toString(),
    );

    itemNoteController = TextEditingController(text: editedOrder.note);
  }

  @override
  void dispose() {
    itemQuantityController.dispose();
    itemNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final typesState = ref.watch(typesProvider);

    return AlertDialog(
      title: const Text('Order Details'),
      content: SizedBox(
        width: 200,
        height: 270,
        child: Form(
          key: _formStateKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              itemsState.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text("Error loading items"),
                data: (items) {
                  editedOrder = editedOrder.copyWith(
                    itemName: editedOrder.itemName.isEmpty
                        ? items.first.name
                        : editedOrder.itemName,
                  );
                  if (items.isEmpty) return const Text("No items found");
                  return Row(
                    children: [
                      Expanded(child: Text("Item Name: ")),
                      Expanded(
                        child: DropdownButton(
                          isExpanded: true,
                          items: items.map((value) {
                            return DropdownMenuItem(
                              value: value.name,
                              child: Text(
                                value.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          value: editedOrder.itemName.isEmpty
                              ? items.first.name
                              : editedOrder.itemName,
                          onChanged: (newValue) {
                            setState(() {
                              editedOrder = editedOrder.copyWith(
                                itemName: newValue.toString(),
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 15),
              typesState.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text("Error loading types"),
                data: (types) {
                  final typeNames = [...types.map((t) => t.type), "None"];
                  editedOrder = editedOrder.copyWith(
                    type: editedOrder.type.isEmpty
                        ? typeNames.first
                        : editedOrder.type,
                  );
                  return Row(
                    children: [
                      Expanded(child: Text("Item Type: ")),
                      Expanded(
                        child: DropdownButton(
                          isExpanded: true,
                          items: typeNames.map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(
                                value,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          value: editedOrder.type.isEmpty
                              ? typeNames.first
                              : editedOrder.type,
                          onChanged: (newValue) {
                            setState(() {
                              editedOrder = editedOrder.copyWith(
                                type: newValue.toString(),
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: itemQuantityController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please Enter Quantity";
                  }
                  if (int.tryParse(value) == null) return "Invalid number";
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (newQuantity) {
                  if (newQuantity.isNotEmpty) {
                    editedOrder = editedOrder.copyWith(
                      quantity: int.parse(newQuantity),
                    );
                  }
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                keyboardType: TextInputType.multiline,
                maxLines: null,
                controller: itemNoteController,
                decoration: InputDecoration(
                  labelText: "Note",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (newNote) {
                  editedOrder = editedOrder.copyWith(note: newNote);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_formStateKey.currentState!.validate()) {
              await widget.onSave(editedOrder);
              if (!context.mounted) return;
              Navigator.pop(context);
            }
          },
          child: Text("Save Order"),
        ),
      ],
    );
  }
}
