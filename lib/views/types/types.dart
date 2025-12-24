import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/viewmodels/types_viewmodel.dart';
import 'package:order_manager/views/types/type_delete_dialog.dart';
import 'package:order_manager/views/types/type_edit_dialog.dart';
import 'package:order_manager/views/ui_utils.dart';

class Types extends ConsumerWidget {
  const Types({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesState = ref.watch(typesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Types")),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Type",
        child: const Icon(Icons.add),
        onPressed: () {
          showAddItemDialog(Type1(id: "", price: 0, type: ""), context, ref);
        },
      ),
      body: typesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (types) {
          if (types.isEmpty) {
            return const Center(child: Text("No Types"));
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: types.length,
            itemBuilder: (BuildContext context, int index) {
              final Type1 type = types[index];
              return Card(
                child: ListTile(
                  title: Text("Type: ${type.type}"),
                  subtitle: Text("Price: ${type.price}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        child: const Tooltip(
                          message: "Edit Type",
                          child: Icon(Icons.edit, color: Colors.blue),
                        ),
                        onTap: () {
                          showAddItemDialog(type, context, ref);
                        },
                      ),
                      Container(margin: const EdgeInsets.only(right: 10.0)),
                      GestureDetector(
                        child: const Tooltip(
                          message: "Delete Type",
                          child: Icon(Icons.delete, color: Colors.red),
                        ),
                        onTap: () {
                          showConfirmDeleteDialog(context, ref, type);
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

  void showAddItemDialog(Type1 type, BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => TypeEditDialog(
        initialType: type,
        onSave: (updatedType) async {
          await ref.read(typesViewModelProvider.notifier).saveType(updatedType);
          if (!context.mounted) return;
          showSnackBar("Type Saved Successfully...", context);
        },
      ),
    );
  }

  void showConfirmDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Type1 type,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => TypeDeleteDialog(
        initialType: type,
        onDelete: (type) async {
          await ref.read(typeRepositoryProvider).deleteType(type);
          if (!context.mounted) return;
          showSnackBar("Type Deleted Successfully", context);
        },
      ),
    );
  }
}
