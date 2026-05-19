abstract class ItemRemoteDataSource {
  Stream<Object?> watchItems();
  Future<Object?> queryById(String id);
  Future<Object?> queryByName(String name);
  Future<String> generateId();
  Future<void> save(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<bool> hasItems();
}
