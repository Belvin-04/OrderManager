import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/app_user.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/providers/app_user_provider.dart';
import 'package:order_manager/repositories/abstract_files/app_user_repository.dart';

class AppUserViewModel extends Notifier<void> {
  @override
  void build() {}

  Future<void> addBusinessEmployee(BusinessEmployee businessEmployee) async {
    final AppUserRepository appUserRepository = ref.read(
      appUserRepositoryProvider,
    );
    await appUserRepository.addBusinessEmployee(businessEmployee);
  }

  Future<void> removeBusinessEmployee(BusinessEmployee businessEmployee) async {
    final AppUserRepository appUserRepository = ref.read(
      appUserRepositoryProvider,
    );
    await appUserRepository.removeBusinessEmployee(businessEmployee);
  }

  Future<void> saveUser(AppUser appUser) async {
    final AppUserRepository appUserRepository = ref.read(
      appUserRepositoryProvider,
    );
    await appUserRepository.saveUser(appUser);
  }

  Future<bool> doesEmployeeExists(
    String employeeEmail,
    String businessId,
  ) async {
    final employees = await ref
        .read(appUserRepositoryProvider)
        .watchBusinessEmployees(businessId)
        .first;
    if (employees.isEmpty) {
      return false;
    }
    return employees.any((employee) => employee.employeeEmail == employeeEmail);
  }

  Future<bool> doesAppUserExists(String email) async {
    final AppUserRepository appUserRepository = ref.read(
      appUserRepositoryProvider,
    );
    AppUser? appUser = await appUserRepository.queryByEmail(email);
    return appUser != null;
  }

  Future<BusinessEmployee?> queryBusinessEmployeeByEmail(
    String employeeEmail,
    String businessId,
  ) async {
    final employees = await ref
        .read(appUserRepositoryProvider)
        .watchBusinessEmployees(businessId)
        .first;
    if (employees.isEmpty) {
      return null;
    }
    final filtered = employees.where(
      (employee) => employee.employeeEmail == employeeEmail,
    );
    if (filtered.isEmpty) {
      return null;
    }
    return filtered.first;
  }
}
