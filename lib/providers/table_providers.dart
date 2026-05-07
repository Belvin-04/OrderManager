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

final tableOrderStatus = StreamProvider.family<TableOrderStatus, String>((
  ref,
  tableNo,
) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.watchOrdersForTable(tableNo).map((orders) {
    if (orders.isNotEmpty) {
      final hasPending = orders.any((o) => o.status == "pending");
      if (hasPending) return TableOrderStatus.pending;

      final hasCompleted = orders.any((o) => o.status == "completed");
      if (hasCompleted) return TableOrderStatus.completed;

      final hasCanceled = orders.any((o) => o.status == "canceled");
      if (hasCanceled) return TableOrderStatus.canceled;
    }
    return TableOrderStatus.empty;
  });
});

final tablePopupProvider = NotifierProvider<PopupNotifier, int>(() {
  return PopupNotifier();
});
