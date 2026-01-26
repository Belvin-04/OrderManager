import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/item_remote_data_source.dart';
import 'package:order_manager/repositories/firebase_item_repository.dart';

class MockItemRemoteDataSource extends Mock implements ItemRemoteDataSource {}

void main() {
  late MockItemRemoteDataSource remote;
  late FirebaseItemRepository repository;

  setUp(() {
    remote = MockItemRemoteDataSource();
    repository = FirebaseItemRepository(remote);
  });

  test('watchItems returns empty list when data is null', () async {
    when(
      () => remote.watchItems(),
    ).thenAnswer((_) => Stream<Object?>.value(null));

    final result = await repository.watchItems().first;

    expect(result, isEmpty);
  });

  test('watchItems maps raw data to Item list', () async {
    when(() => remote.watchItems()).thenAnswer(
      (_) => Stream<Object?>.value({
        '1': {'id': '1', 'name': 'Item A', 'price': 10},
        '2': {'id': '2', 'name': 'Item B', 'price': 20},
      }),
    );

    final result = await repository.watchItems().first;

    expect(result.length, 2);
    expect(result.first.name, 'Item A');
  });

  test('getItem returns null when not found', () async {
    when(() => remote.queryByName('X')).thenAnswer((_) async => null);

    final result = await repository.getItem('X');

    expect(result, isNull);
  });

  test('getItem returns first matching item', () async {
    when(() => remote.queryByName('Item A')).thenAnswer(
      (_) async => {
        'k1': {'id': '1', 'name': 'Item A', 'price': 10},
      },
    );

    final result = await repository.getItem('Item A');

    expect(result!.id, '1');
  });

  test('saveItem reuses existing id when item exists', () async {
    when(() => remote.queryByName('Item A')).thenAnswer(
      (_) async => {
        'k1': {'id': 'existing-id', 'name': 'Item A', 'price': 10},
      },
    );
    when(() => remote.save(any(), any())).thenAnswer((_) async {});

    final item = Item(id: '', name: 'Item A', price: 10);

    await repository.saveItem(item);

    verifyNever(() => remote.generateId());
    verify(() => remote.save('existing-id', any())).called(1);
  });

  test('saveItem uses provided id when present', () async {
    when(() => remote.queryByName('Item A')).thenAnswer(
      (_) async => {
        'k1': {'id': 'existing-id', 'name': 'Item A', 'price': 10},
      },
    );

    when(() => remote.save(any(), any())).thenAnswer((_) async {});

    final item = Item(id: 'existing-id', name: 'Item A', price: 10);

    await repository.saveItem(item);

    verifyNever(() => remote.generateId());
    verify(() => remote.save('existing-id', any())).called(1);
  });

  test('saveItem generates id when new item', () async {
    when(() => remote.queryByName('Item A')).thenAnswer((_) async => null);
    when(() => remote.generateId()).thenAnswer((_) async => 'new-id');
    when(() => remote.save(any(), any())).thenAnswer((_) async {});

    final item = Item(id: '', name: 'Item A', price: 10);

    await repository.saveItem(item);

    verify(() => remote.generateId()).called(1);
    verify(() => remote.save('new-id', any())).called(1);
  });

  test('deleteItem deletes item by id', () async {
    when(() => remote.delete('1')).thenAnswer((_) async {});

    await repository.deleteItem(Item(id: '1', name: 'Item A', price: 10));

    verify(() => remote.delete('1')).called(1);
  });
}
