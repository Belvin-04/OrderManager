abstract class AppUserRemoteDataSource {
  Future<void> saveUser(String id, Map<String, dynamic> data);
  Future<void> deleteUser(String id);
  Future<Object?> queryById(String id);
  Stream<Object?> watchBusinessUsers(String businessId);
  Future<Object?> queryByEmail(String email);
}
