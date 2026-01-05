import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/repositories/firebase_repository.dart';
import 'package:order_manager/repositories/items_repository.dart';
import 'package:order_manager/repositories/order_repository.dart';
import 'package:order_manager/repositories/table_repository.dart';
import 'package:order_manager/repositories/type_repository.dart';
import 'package:order_manager/utils/theme_provider.dart';
import 'package:order_manager/viewmodels/items_viewmodel.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';
import 'package:order_manager/viewmodels/types_viewmodel.dart';

final firebaseDatabaseProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase.instance;
});

final typesRefProvider = Provider<DatabaseReference>((ref) {
  return ref.read(firebaseDatabaseProvider).ref('types');
});

final typeRepositoryProvider = Provider<TypeRepository>((ref) {
  final typesRef = ref.read(typesRefProvider);
  return FirebaseTypeRepository(typesRef);
});

final itemsRefProvider = Provider<DatabaseReference>((ref) {
  return ref.read(firebaseDatabaseProvider).ref('items');
});

final itemRepositoryProvider = Provider<ItemsRepository>((ref) {
  final itemsRef = ref.read(itemsRefProvider);
  return FirebaseItemRepository(itemsRef);
});

final tablesRefProvider = Provider<DatabaseReference>((ref) {
  return ref.read(firebaseDatabaseProvider).ref('tables');
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  final tablesRef = ref.read(tablesRefProvider);
  return FirebaseTableRepository(tablesRef);
});

final orderRefProvider = Provider<DatabaseReference>((ref) {
  return ref.read(firebaseDatabaseProvider).ref('orders');
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final ordersRef = ref.read(orderRefProvider);
  final splitRef = ref.read(splitOrderRefProvider);
  return FirebaseOrderRepository(ordersRef, splitOrderReference: splitRef);
});

final splitOrderRefProvider = Provider<DatabaseReference>((ref) {
  return ref.read(firebaseDatabaseProvider).ref('split-orders');
});

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

final itemsProvider = StreamProvider<List<Item>>((ref) {
  return ref.read(itemRepositoryProvider).watchItems();
});

final itemsViewModelProvider = AsyncNotifierProvider<ItemsViewmodel, void>(() {
  return ItemsViewmodel();
});

final tablesProvider = StreamProvider<List<Table1>>((ref) {
  return ref.read(tableRepositoryProvider).watchTables();
});

final tablesViewmodelProvider = AsyncNotifierProvider<TablesViewmodel, void>(
  TablesViewmodel.new,
);

final typesViewModelProvider =
    AsyncNotifierProvider<TypesViewModel, List<Type1>>(() {
      return TypesViewModel();
    });

final typesProvider = StreamProvider<List<Type1>>((ref) {
  return ref.read(typeRepositoryProvider).watchTypes();
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

final splitOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref.watch(orderRepositoryProvider).watchSplitOrders(tableNo);
});

final completedOrdersProvider = StreamProvider.family<List<Order>, String>((
  ref,
  tableNo,
) {
  return ref
      .watch(orderRepositoryProvider)
      .watchOrdersByStatus("completed", tableNo);
});

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
