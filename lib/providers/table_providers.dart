import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';
import 'package:order_manager/repositories/firebase_table_repository.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_table_remote_data_source.dart';
import 'package:order_manager/utils/popup_notifier.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';

final tablesRefProvider = Provider<DatabaseReference>((ref) {
  return ref.read(firebaseDatabaseProvider).ref('tables');
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  final tablesRef = ref.read(tablesRefProvider);
  final remote = FirebaseTableRemoteDataSource(tablesRef);
  return FirebaseTableRepository(remote);
});

final tablesProvider = StreamProvider<List<Table1>>((ref) {
  return ref.read(tableRepositoryProvider).watchTables();
});

final tablesViewmodelProvider = AsyncNotifierProvider<TablesViewmodel, void>(
  TablesViewmodel.new,
);

final tableOrderStatus = StreamProvider.family<TableOrderStatus, String>((
  ref,
  tableNo,
) {
  return ref
      .watch(tablesViewmodelProvider.notifier)
      .getTableOrderStatus(tableNo);
});

final tablePopupProvider = NotifierProvider<PopupNotifier, int>(() {
  return PopupNotifier();
});
