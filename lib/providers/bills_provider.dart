import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/providers/order_providers.dart';

final billOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.watchNonCanceledOrdersForTable(tableNo).map((orderList) {
    Map<String, Order> orderMap = {};
    for (final Order order in orderList) {
      final key = '${order.item.name} ${order.type.getType(1)}';
      if (orderMap.containsKey(key)) {
        final existingOrder = orderMap[key]!;
        final updatedOrder = existingOrder.copyWith(
          quantity: existingOrder.quantity + order.quantity,
          amount: existingOrder.amount + order.amount,
        );
        orderMap[key] = updatedOrder;
      } else {
        orderMap[key] = order;
      }
    }
    return orderMap.values.toList();
  });
});

final billTotalsProvider = Provider.family<Map<String, int>, String>((
  ref,
  tableNo,
) {
  final repo = ref.watch(orderRepositoryProvider);
  final orders = ref.watch(billOrdersProvider(tableNo)).value ?? [];
  return repo.getBillTotals(orders);
});
