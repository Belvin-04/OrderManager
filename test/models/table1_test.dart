import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';

Table1 buildTable({
  String id = 't1',
  int tableNo = 5,
  int splitNo = 2,
  Offset position = const Offset(150, 250),
}) {
  return Table1(id: id, tableNo: tableNo, splitNo: splitNo, position: position);
}

void main() {
  test('Table1 toMap converts table to correct map structure', () {
    final table = buildTable();

    final map = table.toMap();

    expect(map['id'], 't1');
    expect(map['tableNo'], 5);
    expect(map['splitNo'], 2);

    expect(map['position'], isA<Map<String, double>>());
    expect(map['position']['x'], 150);
    expect(map['position']['y'], 250);
  });

  test('Table1 fromMap recreates identical Table1 from map', () {
    final original = buildTable();

    final map = original.toMap();
    final recreated = Table1.fromMap(map);

    expect(recreated.id, original.id);
    expect(recreated.tableNo, original.tableNo);
    expect(recreated.splitNo, original.splitNo);
    expect(recreated.position, original.position);
  });

  test('Table1 fromMap defaults splitNo to 0 when missing', () {
    final map = {
      'id': 't1',
      'tableNo': 3,
      'position': {'x': 100, 'y': 100},
    };

    final table = Table1.fromMap(map);

    expect(table.splitNo, 0);
  });

  test('Table1 serializes and deserializes correctly', () {
    final table = Table1(
      id: 't1',
      tableNo: 5,
      splitNo: 2,
      position: const Offset(150, 300),
    );

    final map = table.toMap();
    final restored = Table1.fromMap(map);

    expect(restored, table);
    expect(restored.position, const Offset(150, 300));
  });

  test('Table1 uses default values correctly', () {
    final table = Table1(id: 't1', tableNo: 1);

    expect(table.splitNo, 0);
    expect(table.position, const Offset(100, 100));
  });

  test('Table1 copyWith overrides selected fields', () {
    final table = Table1(id: 't1', tableNo: 1);

    final updated = table.copyWith(tableNo: 2);

    expect(updated.id, 't1');
    expect(updated.tableNo, 2);
  });

  test('Table1 equality is based on id only', () {
    final t1 = Table1(id: 'x', tableNo: 1);
    final t2 = Table1(id: 'x', tableNo: 99);

    expect(t1, equals(t2));
    expect(t1.hashCode, t2.hashCode);
  });

  test('Offset.toMap converts dx and dy correctly', () {
    const offset = Offset(10.5, 20.25);

    final map = offset.toMap();

    expect(map, {'x': 10.5, 'y': 20.25});
  });

  test('Offset map conversion is stable', () {
    const offset = Offset(10.5, 20.25);
    final map = offset.toMap();
    final restored = Table1.fromOffsetMap(map);

    expect(restored, offset);
  });

  test('Table1 toString returns formatted table details', () {
    final table = buildTable();

    final result = table.toString();

    expect(result, contains('Id: t1'));
    expect(result, contains('Table No: 5'));
  });
}
