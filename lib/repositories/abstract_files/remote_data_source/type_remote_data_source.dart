abstract class TypeRemoteDataSource {
  Stream<Object?> watchTypes();
  Future<Object?> queryByType(String type);
  Future<Object?> queryById(String id);
  Future<String> generateId();
  Future<void> save(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
}
