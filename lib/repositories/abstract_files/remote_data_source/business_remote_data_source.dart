abstract class BusinessRemoteDataSource {
  Stream<Object?> watchBusiness();
  Future<void> save(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<Object?> queryById(String id);
  Future<String> generateId();
  Future<void> deleteBusinessCollections(String businessId);
}
