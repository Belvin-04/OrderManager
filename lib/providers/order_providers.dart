import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/firebase_order_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_order_remote_data_source.dart';
import 'package:order_manager/utils/quick_order_cart.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';

final orderRefProvider = Provider<CollectionReference<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(firebaseFirestoreProvider).collection('orders');
});

final splitOrderRefProvider =
    Provider<CollectionReference<Map<String, dynamic>>>((ref) {
      return ref.watch(firebaseFirestoreProvider).collection('split-orders');
    });

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final ordersRef = ref.watch(orderRefProvider);
  final splitRef = ref.watch(splitOrderRefProvider);
  final businessId = ref.watch(currentBusinessIdProvider);
  final remote = FirebaseOrderRemoteDataSource(
    ordersRef,
    splitRef,
    businessId: businessId,
  );
  return FirebaseOrderRepository(remote, businessId: businessId);
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
