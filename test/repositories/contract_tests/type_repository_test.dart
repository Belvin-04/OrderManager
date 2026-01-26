import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/type.dart';
import 'in_memory/in_memory_type_repository.dart';

void main() {
  late InMemoryTypeRepository repo;

  setUp(() {
    repo = InMemoryTypeRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('saveType and getType work', () async {
    final type = Type1(id: '1', type: 'Extra', price: 20);

    await repo.saveType(type);

    final fetched = await repo.getType('Extra');

    expect(fetched, equals(type));
  });

  test('saveType overwrites existing type with same name', () async {
    await repo.saveType(Type1(id: '1', type: 'Extra', price: 20));
    await repo.saveType(Type1(id: '', type: 'Extra', price: 30));

    final fetched = await repo.getType('Extra');

    expect(fetched!.price, 30);
    expect(fetched.id, '1');
  });

  test('deleteType removes type', () async {
    final type = Type1(id: '1', type: 'Extra', price: 20);
    await repo.saveType(type);

    await repo.deleteType(type);

    final fetched = await repo.getType('Extra');

    expect(fetched, isNull);
  });

  test('watchTypes emits values when data changes', () async {
    final stream = repo.watchTypes();

    await repo.saveType(Type1(id: '1', type: 'Extra', price: 20));

    final types = await stream.first;

    expect(types.length, 1);
    expect(types.first.type, 'Extra');
  });

  test('empty repository returns empty list', () async {
    final types = await repo.watchTypes().first;

    expect(types, isEmpty);
  });
}
