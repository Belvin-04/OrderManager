import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';

class TotalAmount extends ConsumerWidget {
  final Table1 table;

  const TotalAmount({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<int>(
      stream: ref
          .read(orderRepositoryProvider)
          .getTotalAmountForTable(table.getTableNo().toString()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final total = snapshot.data ?? 0;

        if (total == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(right: 10.0),
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Text('\u{20B9}$total', style: const TextStyle(fontSize: 14)),
        );
      },
    );
  }
}
