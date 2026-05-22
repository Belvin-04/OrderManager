import 'package:order_manager/models/type.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/type_remote_data_source.dart';
import 'package:order_manager/repositories/abstract_files/type_repository.dart';

class FirebaseTypeRepository implements TypeRepository {
  final TypeRemoteDataSource remote;
  final String businessId;

  FirebaseTypeRepository(this.remote, {required this.businessId});

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
    final id = type.id.isEmpty ? await remote.generateId() : type.id;

    final data = type.copyWith(id: id, businessId: businessId).toMap();
    await remote.save(id, data);
  }

  @override
  Future<void> deleteType(Type1 type) {
    return remote.delete(type.id);
  }

  @override
  Future<Type1?> getTypeById(String id) async {
    if (id.isEmpty) return null;
    final raw = await remote.queryById(id);
    if (raw == null) return null;

    final map = raw as Map;
    final first = map.values.first;
    return Type1.fromMap(Map<String, dynamic>.from(first));
  }

  @override
  Future<bool> typesExist() async {
    return remote.hasTypes();
  }
}
