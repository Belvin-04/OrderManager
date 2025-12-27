import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/type.dart';
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
                error: (e, _) => const Text("Error loading items"),
                data: (items) {
                  editedOrder = editedOrder.copyWith(
                    item: editedOrder.item.name.isEmpty
                        ? items.first
                        : editedOrder.item,
                  );
                  if (items.isEmpty) return const Text("No items found");
                  return Row(
                    children: [
                      const Expanded(child: Text("Item Name: ")),
                      Expanded(
                        child: DropdownButton(
                          isExpanded: true,
                          items: items.map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(
                                value.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          value: editedOrder.item.name.isEmpty
                              ? items.first
                              : editedOrder.item,
                          onChanged: (newValue) {
                            setState(() {
                              editedOrder = editedOrder.copyWith(
                                item: newValue as Item,
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
                error: (e, _) => const Text("Error loading types"),
                data: (types) {
                  editedOrder = editedOrder.copyWith(
                    type: editedOrder.type.type.isEmpty
                        ? types.first
                        : editedOrder.type,
                  );
                  return Row(
                    children: [
                      const Expanded(child: Text("Item Type: ")),
                      Expanded(
                        child: DropdownButton(
                          isExpanded: true,
                          items: types.map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(
                                value.type,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          value: editedOrder.type.type.isEmpty
                              ? types.first
                              : editedOrder.type,
                          onChanged: (newValue) {
                            setState(() {
                              editedOrder = editedOrder.copyWith(
                                type: newValue as Type1,
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
          child: const Text("Save Order"),
        ),
      ],
    );
  }
}
