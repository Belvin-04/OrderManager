import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/business_remote_data_source.dart';
import 'package:order_manager/repositories/firebase_business_repository.dart';

import '../test_helper.dart';

class MockBusinessRemoteDataSource extends Mock
    implements BusinessRemoteDataSource {}

void main() {
  late FirebaseBusinessRepository repository;
  late MockBusinessRemoteDataSource remote;

  const business = Business(id: 'b1', name: 'Test Business', ownerId: 'owner1');

  setUpAll(() {
    registerFallbackValue(FakeBusiness());
  });

  setUp(() {
    remote = MockBusinessRemoteDataSource();
    repository = FirebaseBusinessRepository(remote);
  });

  test('saveBusiness generates id when business id is empty', () async {
    when(() => remote.generateId()).thenAnswer((_) async => 'generated_id');

    when(() => remote.save(any(), any())).thenAnswer((_) async {});

    final result = await repository.saveBusiness(
      const Business(id: '', name: 'Test Business', ownerId: 'owner1'),
    );

    expect(result.id, 'generated_id');

    verify(() => remote.generateId()).called(1);

    verify(() => remote.save('generated_id', any())).called(1);
  });

  test('saveBusiness keeps existing id', () async {
    when(() => remote.save(any(), any())).thenAnswer((_) async {});

    final result = await repository.saveBusiness(business);

    expect(result.id, 'b1');

    verifyNever(() => remote.generateId());

    verify(() => remote.save('b1', any())).called(1);
  });

  test('deleteBusiness calls remote delete', () async {
    when(() => remote.delete(any())).thenAnswer((_) async {});

    await repository.deleteBusiness(business);

    verify(() => remote.delete('b1')).called(1);
  });

  test('watchBusiness returns empty list when remote emits null', () async {
    when(() => remote.watchBusiness()).thenAnswer((_) => Stream.value(null));

    final result = await repository.watchBusiness().first;

    expect(result, isEmpty);
  });

  test('watchBusiness maps businesses correctly', () async {
    when(() => remote.watchBusiness()).thenAnswer(
      (_) => Stream.value({
        'b1': {'id': 'b1', 'name': 'Business A', 'ownerId': 'owner1'},
        'b2': {'id': 'b2', 'name': 'Business B', 'ownerId': 'owner1'},
      }),
    );

    final result = await repository.watchBusiness().first;

    expect(result.length, 2);

    expect(result[0].name, 'Business A');
    expect(result[1].name, 'Business B');
  });

  test('watchBusiness sorts businesses alphabetically', () async {
    when(() => remote.watchBusiness()).thenAnswer(
      (_) => Stream.value({
        'b2': {'id': 'b2', 'name': 'Zoo Business', 'ownerId': 'owner1'},
        'b1': {'id': 'b1', 'name': 'Alpha Business', 'ownerId': 'owner1'},
      }),
    );

    final result = await repository.watchBusiness().first;

    expect(result[0].name, 'Alpha Business');
    expect(result[1].name, 'Zoo Business');
  });

  test(
    'deleteBusinessCollections calls remote deleteBusinessCollections',
    () async {
      when(
        () => remote.deleteBusinessCollections(any()),
      ).thenAnswer((_) async {});

      await repository.deleteBusinessCollections('b1');

      verify(() => remote.deleteBusinessCollections('b1')).called(1);
    },
  );
}
