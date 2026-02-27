import 'package:flutter/material.dart';
import 'package:order_manager/models/order.dart';

class QuickOrder extends StatelessWidget {
  final Order order;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuickOrder({
    super.key,
    required this.order,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("${order.item.name} ${order.type.getType(0)}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 0 ? onDecrement : null,
            icon: const Icon(Icons.remove),
          ),
          Text("$quantity"),
          IconButton(onPressed: onIncrement, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}
