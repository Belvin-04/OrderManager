import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/providers/app_user_provider.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/viewmodels/app_user_viewmodel.dart';

final employeeViewModelProvider = NotifierProvider<AppUserViewModel, void>(
  AppUserViewModel.new,
);

final employeesProvider = StreamProvider.family<List<BusinessEmployee>, String>(
  (ref, businessId) {
    return ref
        .watch(appUserRepositoryProvider)
        .watchBusinessEmployees(businessId);
  },
);

final isEmployeeProvider = Provider<bool>((ref) {
  final selectedBusiness = ref.watch(selectedBusinessProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  if (selectedBusiness == null || currentUserId == null) {
    return false;
  }
  return selectedBusiness.ownerId != currentUserId;
});
