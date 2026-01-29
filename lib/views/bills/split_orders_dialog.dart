import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/providers/providers.dart';

class SplitOrdersDialog extends ConsumerWidget {
  final List<Order> orders;
  final void Function(Order order) onSelect;

  const SplitOrdersDialog({
    super.key,
    required this.orders,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return AlertDialog(
      title: const Text("Split Orders"),
      content: SizedBox(
        width: 200,
        height: 200,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              color: themeMode == ThemeMode.dark
                  ? Colors.grey.shade900
                  : Colors.white,
              child: ListTile(
                title: Text(
                  "${orders[index].item.name} ${orders[index].type.getType(0)}",
                ),
                onTap: () {
                  onSelect(order);
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
