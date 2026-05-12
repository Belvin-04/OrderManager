import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/business_employee.dart';
import 'package:order_manager/providers/app_user_provider.dart';
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
