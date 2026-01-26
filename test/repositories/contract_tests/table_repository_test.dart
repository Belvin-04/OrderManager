import 'package:flutter_test/flutter_test.dart';
import 'in_memory/in_memory_table_repository.dart';

void main() {
  late InMemoryTableRepository repo;

  setUp(() {
    repo = InMemoryTableRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('watchTables emits empty list immediately', () async {
    final tables = await repo.watchTables().first;
    expect(tables, isEmpty);
  });

  test('addTable adds a table', () async {
    await repo.addTable(1);

    final tables = await repo.watchTables().first;
    expect(tables.length, 1);
    expect(tables.first.tableNo, 1);
  });

  test('getLastTable returns null when no tables exist', () async {
    final table = await repo.getLastTable();
    expect(table, isNull);
  });

  test('getLastTable returns table with highest tableNo', () async {
    await repo.addTable(1);
    await repo.addTable(3);
    await repo.addTable(2);

    final last = await repo.getLastTable();
    expect(last!.tableNo, 3);
  });

  test('deleteTableById removes table and emits', () async {
    await repo.addTable(1);
    final table = (await repo.watchTables().first).first;

    await repo.deleteTableById(table.id);

    final tables = await repo.watchTables().first;
    expect(tables, isEmpty);
  });

  test('updateTablePosition updates only position', () async {
    await repo.addTable(1);
    final table = (await repo.watchTables().first).first;

    const newPos = Offset(200, 300);
    await repo.updateTablePosition(table.id, newPos);

    final updated = (await repo.watchTables().first).first;
    expect(updated.position, newPos);
    expect(updated.tableNo, table.tableNo);
  });

  test('watchTables emits on changes', () async {
    final future = repo.watchTables().skip(1).first;

    await repo.addTable(1);

    final tables = await future;
    expect(tables.length, 1);
  });
}
