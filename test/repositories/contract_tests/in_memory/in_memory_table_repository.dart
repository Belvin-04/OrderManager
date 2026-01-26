import 'dart:async';
import 'dart:ui' show Offset;

import 'package:order_manager/models/table.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';

class InMemoryTableRepository implements TableRepository {
  final Map<String, Table1> _byId = {};
  int _idCounter = 0;

  late final StreamController<List<Table1>> _controller =
      StreamController<List<Table1>>.broadcast(
        onListen: () {
          _controller.add(_byId.values.toList());
        },
      );

  void _emit() {
    _controller.add(_byId.values.toList());
  }

  @override
  Stream<List<Table1>> watchTables() => _controller.stream;

  @override
  Future<void> addTable(int tableNo) async {
    final id = 'table_${++_idCounter}';
    _byId[id] = Table1(id: id, tableNo: tableNo);
    _emit();
  }

  @override
  Future<Table1?> getLastTable() async {
    if (_byId.isEmpty) return null;

    return _byId.values.reduce((a, b) => a.tableNo > b.tableNo ? a : b);
  }

  @override
  Future<void> deleteTableById(String tableId) async {
    _byId.remove(tableId);
    _emit();
  }

  @override
  Future<void> updateTablePosition(String id, Offset pos) async {
    final table = _byId[id];
    if (table == null) return;

    _byId[id] = table.copyWith(position: pos);
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
