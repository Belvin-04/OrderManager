import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/table_remote_data_source.dart';
import 'package:order_manager/repositories/firebase_table_repository.dart';

class MockTableRemoteDataSource extends Mock implements TableRemoteDataSource {}

void main() {
  late MockTableRemoteDataSource remote;
  late FirebaseTableRepository repository;

  setUp(() {
    remote = MockTableRemoteDataSource();
    repository = FirebaseTableRepository(remote, businessId: 'biz-1');
  });

  test('watchTables returns empty list when no data', () async {
    when(
      () => remote.watchTables(),
    ).thenAnswer((_) => Stream<Object?>.value(null));

    final result = await repository.watchTables().first;

    expect(result, isEmpty);
  });

  test('watchTables maps raw data to Table1 list', () async {
    when(() => remote.watchTables()).thenAnswer(
      (_) => Stream<Object?>.value({
        '1': {
          'id': '1',
          'tableNo': 1,
          'splitNo': 0,
          'position': {'x': 10, 'y': 20},
        },
      }),
    );

    final result = await repository.watchTables().first;

    expect(result.single.tableNo, 1);
    expect(result.single.position.dx, 10);
  });

  test('getLastTable returns null when no tables exist', () async {
    when(() => remote.getLastTable()).thenAnswer((_) async => null);

    final result = await repository.getLastTable();

    expect(result, isNull);
  });

  test('getLastTable returns last table by tableNo', () async {
    when(() => remote.getLastTable()).thenAnswer(
      (_) async => {
        'k1': {
          'id': '3',
          'tableNo': 3,
          'splitNo': 0,
          'position': {'x': 100, 'y': 100},
        },
      },
    );

    final result = await repository.getLastTable();

    expect(result!.tableNo, 3);
  });

  test('addTable generates id and saves table', () async {
    when(() => remote.generateId()).thenAnswer((_) async => 'new-id');
    when(() => remote.save(any(), any())).thenAnswer((_) async {});

    await repository.addTable(5);

    verify(() => remote.save('new-id', any())).called(1);
  });

  test('deleteTableById deletes table by id', () async {
    when(() => remote.delete('1')).thenAnswer((_) async {});

    await repository.deleteTableById('1');

    verify(() => remote.delete('1')).called(1);
  });

  test('updateTablePosition updates only position fields', () async {
    when(() => remote.updatePosition(any(), any())).thenAnswer((_) async {});

    await repository.updateTablePosition('1', const Offset(50, 75));

    verify(() => remote.updatePosition('1', {'x': 50.0, 'y': 75.0})).called(1);
  });
}
