import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/app_user.dart';

final employeesProvider = StreamProvider.family<List<AppUser>, String>((
  ref,
  businessId,
) {
  return Stream.value([
    const AppUser(id: "Id", email: "name@email.com", name: "Name"),
  ]);
});
