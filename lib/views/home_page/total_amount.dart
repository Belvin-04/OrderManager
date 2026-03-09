import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/order_providers.dart';

class TotalAmount extends ConsumerWidget {
  final Table1 table;
  final int splitNo;
  const TotalAmount({super.key, required this.table, this.splitNo = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<int>(
      stream: ref
          .read(ordersViewModelProvider.notifier)
          .getTotalAmountForTable(
            table.tableNo.toString(),
            splitNo: splitNo.toString(),
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final total = snapshot.data ?? 0;

        if (total == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(right: 10.0),
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(border: Border.all(color: Colors.white)),
          child: Text('\u{20B9}$total', style: const TextStyle(fontSize: 14)),
        );
      },
    );
  }
}
