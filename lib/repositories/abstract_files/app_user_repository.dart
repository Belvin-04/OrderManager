import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/models/business_employee.dart'
    show BusinessEmployee;

abstract class AppUserRepository {
  Future<void> saveUser(AppUser user);
  Future<void> deleteUser(String id);
  Future<AppUser?> queryById(String id);
  Future<AppUser?> queryByEmail(String email);
  Stream<List<BusinessEmployee>> watchBusinessEmployees(String businessId);
  Future<void> addBusinessEmployee(BusinessEmployee businessEmployee);
  Future<void> removeBusinessEmployee(BusinessEmployee businessEmployee);
  Stream<List<BusinessEmployee>> watchEmployedBusinesses(AppUser user);
  Future<BusinessEmployee?> getBusinessEmployeeByEmail(
    String email,
    String businessId,
  );
}
