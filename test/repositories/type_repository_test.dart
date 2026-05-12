import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/repositories/firebase_type_repository.dart';
import '../test_helper.dart';

void main() {
  late MockTypeRemoteDataSource remote;
  late FirebaseTypeRepository repository;

  setUp(() {
    remote = MockTypeRemoteDataSource();
    repository = FirebaseTypeRepository(remote, businessId: 'biz-1');
  });
  test('watchTypes returns empty list when data is null', () async {
    when(
      () => remote.watchTypes(),
    ).thenAnswer((_) => Stream<Object?>.value(null));

    final result = await repository.watchTypes().first;

    expect(result, isEmpty);
  });

  test('watchTypes maps firebase data to Type1 list', () async {
    when(() => remote.watchTypes()).thenAnswer(
      (_) => Stream.value({
        '1': {'id': '1', 'type': 'A', 'price': 10},
        '2': {'id': '2', 'type': 'B', 'price': 20},
      }),
    );

    final result = await repository.watchTypes().first;

    expect(result.length, 2);
    expect(result.first.type, 'A');
  });

  test('getType returns null when no data found', () async {
    when(() => remote.queryByType('X')).thenAnswer((_) async => null);

    final result = await repository.getType('X');

    expect(result, isNull);
  });

  test('getType returns first matching Type1', () async {
    when(() => remote.queryByType('A')).thenAnswer(
      (_) async => {
        'k1': {'id': '1', 'type': 'A', 'price': 10},
      },
    );

    final result = await repository.getType('A');

    expect(result!.id, '1');
  });

  test('saveType generates id when id is empty', () async {
    when(() => remote.generateId()).thenAnswer((_) async => 'newId');
    when(() => remote.save(any(), any())).thenAnswer((_) async {});

    final type = Type1(id: '', type: 'A', price: 10);

    await repository.saveType(type);

    verify(() => remote.generateId()).called(1);
    verify(() => remote.save('newId', any())).called(1);
  });

  test('saveType reuses existing id when id exists remotely', () async {
    when(() => remote.save(any(), any())).thenAnswer((_) async {});

    final type = Type1(id: 'existingId', type: 'A', price: 10);

    await repository.saveType(type);
    verifyNever(() => remote.generateId());
    verify(() => remote.save('existingId', any())).called(1);
  });

  test('deleteType deletes by id', () async {
    when(() => remote.delete('1')).thenAnswer((_) async {});

    await repository.deleteType(Type1(id: '1', type: 'A', price: 10));

    verify(() => remote.delete('1')).called(1);
  });
}
