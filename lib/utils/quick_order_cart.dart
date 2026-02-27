import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';

class QuickOrderCart extends Notifier<Map<String, Order>> {
  @override
  Map<String, Order> build() => {};

  void increment(Order order) {
    final key = _key(order);
    final existing = state[key];

    state = {
      ...state,
      key: order.copyWith(quantity: (existing?.quantity ?? 0) + 1),
    };
  }

  void decrement(Order order) {
    final key = _key(order);
    final existing = state[key];
    final qty = (existing?.quantity ?? 0) - 1;

    if (qty <= 0) {
      final newState = {...state};
      newState.remove(key);
      state = newState;
    } else {
      state = {...state, key: order.copyWith(quantity: qty)};
    }
  }

  List<Order> getOrders() => state.values.toList();

  void clear() => state = {};

  String _key(Order order) => "${order.item.name}-${order.type.id}";
}
