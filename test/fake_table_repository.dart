import 'dart:ui' show Offset;

import 'package:order_manager/models/table.dart';
import 'package:order_manager/repositories/table_repository.dart';

class FakeTableRepository implements TableRepository {
  List<Table1> tables = [];
  int? addedTableNo;
  String? deletedTableId;
  Map<String, Offset> updatedPositions = {};

  @override
  Stream<List<Table1>> watchTables() async* {
    yield tables;
  }

  @override
  Future<Table1?> getLastTable() async {
    if (tables.isEmpty) return null;
    tables.sort((a, b) => a.tableNo.compareTo(b.tableNo));
    return tables.last;
  }

  @override
  Future<void> addTable(int tableNo) async {
    addedTableNo = tableNo;
    tables.add(Table1(id: 't$tableNo', tableNo: tableNo));
  }

  @override
  Future<void> deleteTableById(String tableId) async {
    deletedTableId = tableId;
    tables.removeWhere((t) => t.id == tableId);
  }

  @override
  Future<void> updateTablePosition(String id, Offset pos) async {
    updatedPositions[id] = pos;
  }
}
