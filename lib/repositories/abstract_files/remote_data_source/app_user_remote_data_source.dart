abstract class AppUserRemoteDataSource {
  Future<void> saveUser(String id, Map<String, dynamic> data);
  Future<void> deleteUser(String id);
  Future<Object?> queryById(String id);
  Stream<Object?> watchBusinessEmployees(String businessId);
  Future<Object?> queryByEmail(String email);
  Future<void> addBusinessEmployee(
    String relationId,
    Map<String, dynamic> data,
  );
  Future<void> removeBusinessEmployee(String relationId);
}
