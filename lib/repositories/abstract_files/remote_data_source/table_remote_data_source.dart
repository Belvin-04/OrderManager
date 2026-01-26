abstract class TableRemoteDataSource {
  Stream<Object?> watchTables();
  Future<Object?> getLastTable();
  Future<String> generateId();
  Future<void> save(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<void> updatePosition(String id, Map<String, dynamic> pos);
}
