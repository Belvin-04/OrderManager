import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/providers/order_providers.dart';

final billOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref
      .read(ordersViewModelProvider.notifier)
      .getBillOrdersForTable(tableNo);
});

final billTotalsProvider = Provider.family<Map<String, int>, String>((
  ref,
  tableNo,
) {
  final repo = ref.watch(orderRepositoryProvider);
  final orders = ref.watch(billOrdersProvider(tableNo)).value ?? [];
  return repo.getBillTotals(orders);
});
