import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/repositories/abstract_files/app_user_repository.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/app_user_remote_data_source.dart';

class FirebaseAppUserRepository implements AppUserRepository {
  final AppUserRemoteDataSource remote;
  FirebaseAppUserRepository(this.remote);

  @override
  Future<void> saveUser(AppUser user) async {
    return remote.saveUser(user.id, user.toMap());
  }

  @override
  Future<void> deleteUser(String id) {
    return remote.deleteUser(id);
  }

  @override
  Stream<List<BusinessEmployee>> watchBusinessEmployees(String businessId) {
    return remote.watchBusinessEmployees(businessId).map((data) {
      if (data == null) return <BusinessEmployee>[];
      final map = data as Map<String, dynamic>;
      return map.values
          .map((e) => BusinessEmployee.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  @override
  Stream<List<BusinessEmployee>> watchEmployedBusinesses(AppUser user) {
    return remote.watchEmployedBusinesses(user.id).map((data) {
      if (data == null) return <BusinessEmployee>[];
      final map = data as Map<String, dynamic>;
      return map.values
          .map((e) => BusinessEmployee.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  @override
  Future<AppUser?> queryById(String id) async {
    final raw = await remote.queryById(id);
    if (raw == null) {
      return null;
    }
    final map = raw as Map<String, dynamic>;
    final first = map.values.first;
    return AppUser.fromMap(Map<String, dynamic>.from(first));
  }

  @override
  Future<AppUser?> queryByEmail(String email) async {
    final raw = await remote.queryByEmail(email);
    if (raw == null) {
      return null;
    }
    final map = raw as Map<String, dynamic>;
    final first = map.values.first;
    return AppUser.fromMap(Map<String, dynamic>.from(first));
  }

  @override
  Future<void> addBusinessEmployee(BusinessEmployee businessEmployee) async {
    final id = businessEmployee.relationId.isEmpty
        ? '${businessEmployee.businessId}_${businessEmployee.employeeId}'
        : businessEmployee.relationId;
    final updatedEmployee = businessEmployee.copyWith(relationId: id);
    return remote.addBusinessEmployee(id, updatedEmployee.toMap());
  }

  @override
  Future<void> removeBusinessEmployee(BusinessEmployee businessEmployee) {
    return remote.removeBusinessEmployee(businessEmployee.relationId);
  }
}
