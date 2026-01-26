import 'package:order_manager/models/type.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/type_remote_data_source.dart';
import 'package:order_manager/repositories/abstract_files/type_repository.dart';

class FirebaseTypeRepository implements TypeRepository {
  final TypeRemoteDataSource remote;

  FirebaseTypeRepository(this.remote);

  @override
  Stream<List<Type1>> watchTypes() {
    return remote.watchTypes().map((data) {
      if (data == null) return <Type1>[];

      final map = Map<String, dynamic>.from(data as Map);

      return map.values
          .map((e) => Type1.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  @override
  Future<void> saveType(Type1 type) async {
    final existing = await remote.queryByType(type.type);

    String id;

    if (existing is Map && existing.values.isNotEmpty) {
      id = existing.values.first['id'];
    } else {
      id = await remote.generateId();
    }

    final data = type.toMap()..['id'] = id;
    await remote.save(id, data);
  }

  @override
  Future<void> deleteType(Type1 type) {
    return remote.delete(type.id);
  }

  @override
  Future<Type1?> getType(String typeName) async {
    final raw = await remote.queryByType(typeName);
    if (raw == null) return null;

    final map = raw as Map;
    final first = map.values.first;
    return Type1.fromMap(Map<String, dynamic>.from(first));
  }
}
