import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';

void main() {
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
  });

  test('Offset map conversion is stable', () {
    const offset = Offset(10.5, 20.25);
    final map = offset.toMap();
    final restored = Table1.fromOffsetMap(map);

    expect(restored, offset);
  });
}

extension on Offset {
  Map<String, double> toMap() {
    Map<String, double> position = {};
    position["x"] = dx;
    position["y"] = dy;
    return position;
  }
}
