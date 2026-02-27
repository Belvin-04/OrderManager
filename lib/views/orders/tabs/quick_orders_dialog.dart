import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/orders/tabs/quick_order.dart';

class QuickOrdersDialog extends ConsumerWidget {
  final Table1 table;

  const QuickOrdersDialog({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickOrdersState = ref.watch(quickOrdersProvider);
    final cart = ref.watch(quickOrderCartProvider);

    return quickOrdersState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Error: $e")),
      data: (orders) {
        final sortedOrders = [...orders];

        sortedOrders.sort((a, b) {
          final nameA = "${a.item.name} ${a.type.getType(0)}".toLowerCase();
          final nameB = "${b.item.name} ${b.type.getType(0)}".toLowerCase();

          return nameA.compareTo(nameB);
        });

        return AlertDialog(
          content: SizedBox(
            height: 300,
            width: 300,
            child: ListView.builder(
              itemCount: sortedOrders.length,
              itemBuilder: (_, index) {
                final baseOrder = sortedOrders[index].copyWith(
                  id: "",
                  table: table,
                  quantity: 0,
                );

                final key = "${baseOrder.item.name}-${baseOrder.type.id}";

                final quantity = cart[key]?.quantity ?? 0;

                return QuickOrder(
                  order: baseOrder,
                  quantity: quantity,
                  onIncrement: () => ref
                      .read(quickOrderCartProvider.notifier)
                      .increment(baseOrder),
                  onDecrement: () => ref
                      .read(quickOrderCartProvider.notifier)
                      .decrement(baseOrder),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final selectedOrders = ref
                    .read(quickOrderCartProvider.notifier)
                    .getOrders();

                for (final order in selectedOrders) {
                  await ref
                      .read(ordersViewModelProvider.notifier)
                      .saveOrder(order);
                }

                ref.read(quickOrderCartProvider.notifier).clear();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Add Orders"),
            ),
          ],
        );
      },
    );
  }
}
