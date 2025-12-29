import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/viewmodels/items_viewmodel.dart';
import 'package:order_manager/views/items/item_delete_dialog.dart';
import 'package:order_manager/views/items/item_edit_dialog.dart';
import 'package:order_manager/views/ui_utils.dart';

class Items extends ConsumerWidget {
  const Items({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Items")),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Item",
        child: const Icon(Icons.add),
        onPressed: () {
          showAddItemDialog(context, ref, Item(id: "", name: "", price: 0));
        },
      ),
      body: itemsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text("No Items"));
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              Item item = items[index];
              return Card(
                child: ListTile(
                  title: Text("Name: ${item.name}"),
                  subtitle: Text("Price: ${item.price}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        child: const Tooltip(
                          message: "Edit Item",
                          child: Icon(Icons.edit, color: Colors.blue),
                        ),
                        onTap: () {
                          showAddItemDialog(context, ref, item);
                        },
                      ),
                      Container(margin: const EdgeInsets.only(right: 10.0)),
                      GestureDetector(
                        child: const Tooltip(
                          message: "Delete Item",
                          child: Icon(Icons.delete, color: Colors.red),
                        ),
                        onTap: () {
                          showDeleteItemDialog(context, ref, item);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void showAddItemDialog(BuildContext context, WidgetRef ref, Item item) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ItemEditDialog(
        initialItem: item,
        onSave: (item) async {
          await ref.read(itemsViewModelProvider.notifier).saveItem(item);
          if (!context.mounted) return;
          showSnackBar("Item Saved Successfully...", context);
        },
      ),
    );
  }

  void showDeleteItemDialog(BuildContext context, WidgetRef ref, Item item) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ItemDeleteDialog(
        initialItem: item,
        onDelete: (item) async {
          await ref.read(itemRepositoryProvider).deleteItem(item);
          if (!context.mounted) return;
          showSnackBar("Item Deleted Successfully", context);
        },
      ),
    );
  }
}
