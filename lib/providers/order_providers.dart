import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/firebase_order_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_order_remote_data_source.dart';
import 'package:order_manager/utils/quick_order_cart.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';

final orderRefProvider = Provider<DatabaseReference>((ref) {
  return ref.read(firebaseDatabaseProvider).ref('orders');
});

final splitOrderRefProvider = Provider<DatabaseReference>((ref) {
  return ref.read(firebaseDatabaseProvider).ref('split-orders');
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final ordersRef = ref.read(orderRefProvider);
  final splitRef = ref.read(splitOrderRefProvider);
  final remote = FirebaseOrderRemoteDataSource(ordersRef, splitRef);
  return FirebaseOrderRepository(remote);
});

final ordersViewModelProvider = AsyncNotifierProvider<OrdersViewModel, void>(
  () {
    return OrdersViewModel();
  },
);

final cancelledOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref
      .watch(orderRepositoryProvider)
      .watchOrdersByStatus("canceled", tableNo);
});

final pendingOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref
      .watch(orderRepositoryProvider)
      .watchOrdersByStatus("pending", tableNo);
});

final completedOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref
      .watch(orderRepositoryProvider)
      .watchOrdersByStatus("completed", tableNo);
});

final quickOrdersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).watchOrdersForTable("0");
});

final quickOrderCartProvider =
    NotifierProvider<QuickOrderCart, Map<String, Order>>(QuickOrderCart.new);

final splitOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref.watch(orderRepositoryProvider).watchSplitOrders(tableNo);
});
