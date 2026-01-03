import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/views/orders/orders.dart';

class TableWidget extends ConsumerWidget {
  final Table1 table;

  const TableWidget({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Orders(table)),
        );
      },
      child: LongPressDraggable<Table1>(
        data: table,
        feedback: Material(
          color: Colors.transparent,
          child: _buildTableIcon(Colors.blue.withValues(alpha: 0.5)),
        ),
        childWhenDragging: _buildTableIcon(Colors.grey),
        child: _buildTableIcon(Colors.blue),
      ),
    );
  }

  Widget _buildTableIcon(Color color) {
    return Column(
      children: [
        Icon(Icons.table_restaurant, size: 40, color: color),
        Text("T${table.tableNo}", style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
