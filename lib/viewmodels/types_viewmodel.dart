import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';

class TypesViewModel extends AsyncNotifier<List<Type1>> {
  @override
  Future<List<Type1>> build() async {
    return ref.watch(typeRepositoryProvider).watchTypes().first;
  }

  Future<void> saveType(Type1 type) async {
    final typesRepo = ref.read(typeRepositoryProvider);
    final oldTypes = await typesRepo.watchTypes().first;
    final oldType = oldTypes.firstWhere(
      (t) => t.id == type.id,
      orElse: () => type,
    );

    await typesRepo.saveType(type);
    if (type.id.isEmpty) return;
    await updateOrderPricesAndNames(oldType, type);
  }

  Future<void> deleteType(Type1 type) async {
    await ref.read(typeRepositoryProvider).deleteType(type);
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
