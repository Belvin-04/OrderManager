import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/type_providers.dart';

class TypesViewModel extends AsyncNotifier<List<Type1>> {
  @override
  Future<List<Type1>> build() async {
    return ref.watch(typeRepositoryProvider).watchTypes().first;
  }

  Future<void> saveType(Type1 type) async {
    final typesRepo = ref.read(typeRepositoryProvider);
    final oldType = await typesRepo.getTypeById(type.id);
    await typesRepo.saveType(type);
    if (oldType == null) return;
    await updateOrderPricesAndNames(oldType, type);
  }

  Future<bool> deleteType(Type1 type) async {
    final canDelete = await canDeleteType(type);
    if (!canDelete) return false;
    await ref.read(typeRepositoryProvider).deleteType(type);
    return true;
  }

  Future<bool> canDeleteType(Type1 type) async {
    final orders = await ref
        .read(orderRepositoryProvider)
        .getOrdersByType(type.type);
    return orders.isEmpty;
  }

  Future<void> updateOrderPricesAndNames(Type1 oldType, Type1 type) async {
    final ordersRepo = ref.read(orderRepositoryProvider);
    final orders = await ordersRepo.getOrdersByType(oldType.type);
    for (final order in orders) {
      final item = order.item;
      final newAmount = (item.price + type.price) * order.quantity;

      final updated = order.copyWith(amount: newAmount, type: type);

      await ordersRepo.saveOrder(updated);
    }
  }
}
