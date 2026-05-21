import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';
import 'package:order_manager/repositories/firebase_table_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_table_remote_data_source.dart';
import 'package:order_manager/utils/popup_notifier.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';

final tablesRefProvider = Provider<CollectionReference<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(firebaseFirestoreProvider).collection('tables');
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  final tablesRef = ref.watch(tablesRefProvider);
  final businessId = ref.watch(currentBusinessIdProvider);
  final remote = FirebaseTableRemoteDataSource(
    tablesRef,
    businessId: businessId,
  );
  return FirebaseTableRepository(remote, businessId: businessId);
});

final tablesProvider = StreamProvider<List<Table1>>((ref) {
  return ref.watch(tableRepositoryProvider).watchTables();
});

final tablesViewmodelProvider = AsyncNotifierProvider<TablesViewmodel, void>(
  TablesViewmodel.new,
);

final pendingOrdersExistProvider = StreamProvider.family<bool, String>((
  ref,
  tableKey,
) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.watchPendingOrdersExist(tableKey);
});

final completedOrdersExistProvider = StreamProvider.family<bool, String>((
  ref,
  tableKey,
) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.watchCompletedOrdersExist(tableKey);
});

final canceledOrdersExistProvider = StreamProvider.family<bool, String>((
  ref,
  tableKey,
) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.watchCanceledOrdersExist(tableKey);
});

final tableOrderStatus = Provider.family<AsyncValue<TableOrderStatus>, String>((
  ref,
  tableKey,
) {
  final pending = ref.watch(pendingOrdersExistProvider(tableKey));

  final completed = ref.watch(completedOrdersExistProvider(tableKey));

  final canceled = ref.watch(canceledOrdersExistProvider(tableKey));

  if (pending.isLoading || completed.isLoading || canceled.isLoading) {
    return const AsyncLoading();
  }

  if (pending.value == true) {
    return const AsyncData(TableOrderStatus.pending);
  }

  if (completed.value == true) {
    return const AsyncData(TableOrderStatus.completed);
  }

  if (canceled.value == true) {
    return const AsyncData(TableOrderStatus.canceled);
  }

  return const AsyncData(TableOrderStatus.empty);
});

final tablePopupProvider = NotifierProvider<PopupNotifier, int>(() {
  return PopupNotifier();
});
