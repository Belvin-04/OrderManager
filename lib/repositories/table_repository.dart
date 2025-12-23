import 'package:order_manager/models/table.dart';

abstract class TableRepository {
  Stream<List<Table1>> watchTables();
  Future<Table1?> getLastTable();
  Future<void> addTable(int tableNo);
  Future<void> deleteTableById(String tableId);
}
