import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';

import 'bill_item.dart';

class BillFooter extends ConsumerWidget {
  final Table1 table;
  const BillFooter(this.table, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billTotals = ref.watch(billTotalsProvider(table.tableNo.toString()));
    final totalAmount = billTotals['amount'] ?? 0;
    final totalQuantity = billTotals['quantity'] ?? 0;
    return BillItem("", "$totalQuantity", "$totalAmount", "");
  }
}
