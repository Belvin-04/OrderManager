import 'dart:ui' show Offset;

import 'package:order_manager/models/table.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/table_remote_data_source.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';

class FirebaseTableRepository implements TableRepository {
  final TableRemoteDataSource remote;

  FirebaseTableRepository(this.remote);

  @override
  Future<void> addTable(int tableNo) async {
    final id = await remote.generateId();
    final table = Table1(tableNo: tableNo, id: id);
    await remote.save(id, table.toMap());
  }

  @override
  Future<Table1?> getLastTable() async {
    final lastTable = await remote.getLastTable();
    if (lastTable == null) return null;

    final map = lastTable as Map;
    final first = map.values.first;
    return Table1.fromMap(Map<String, dynamic>.from(first));
  }

  @override
  Stream<List<Table1>> watchTables() {
    return remote.watchTables().map((data) {
      if (data == null) return <Table1>[];

      final map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((e) => Table1.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  @override
  Future<void> deleteTableById(String tableId) {
    return remote.delete(tableId);
  }

  @override
  Future<void> updateTablePosition(String id, Offset pos) {
    return remote.updatePosition(id, {'x': pos.dx, 'y': pos.dy});
  }
}
