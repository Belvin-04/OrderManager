import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/repositories/firebase_repository.dart';
import 'package:order_manager/repositories/items_repository.dart';
import 'package:order_manager/repositories/order_repository.dart';
import 'package:order_manager/repositories/table_repository.dart';
import 'package:order_manager/repositories/type_repository.dart';
import 'package:order_manager/utils/theme_provider.dart';

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
  return FirebaseOrderRepository(ordersRef);
});

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
