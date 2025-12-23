import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';

final typesViewModelProvider =
    AsyncNotifierProvider<TypesViewModel, List<Type1>>(() {
      return TypesViewModel();
    });

final typesProvider = StreamProvider<List<Type1>>((ref) {
  return ref.read(typeRepositoryProvider).watchTypes();
});

class TypesViewModel extends AsyncNotifier<List<Type1>> {
  @override
  Future<List<Type1>> build() async {
    return ref.watch(typeRepositoryProvider).watchTypes().first;
  }

  Future<void> saveType(Type1 type) async {
    final typesRepo = ref.read(typeRepositoryProvider);
    final oldTypes = state.value ?? [];
    final oldType = oldTypes.firstWhere(
      (t) => t.id == type.id,
      orElse: () => type,
    );

    await typesRepo.saveType(type);
    if (type.getId().isEmpty) return;
    await updateOrderPricesAndNames(oldType, type);
  }

  Future<void> deleteType(Type1 type) async {
    await ref.read(typeRepositoryProvider).deleteType(type);
  }

  Future<void> updateOrderPricesAndNames(Type1 oldType, Type1 type) async {
    final ordersRepo = ref.read(orderRepositoryProvider);
    final orders = await ordersRepo.getOrdersByType(oldType.getType());
    for (final order in orders) {
      final item = await ref
          .read(itemRepositoryProvider)
          .getItem(order.itemName);
      final newAmount = (item!.price + type.price) * order.quantity;
      final newName = type.getType();

      final updated = order.copyWith(amount: newAmount, type: newName);

      await ordersRepo.saveOrder(updated);
    }
  }
}
