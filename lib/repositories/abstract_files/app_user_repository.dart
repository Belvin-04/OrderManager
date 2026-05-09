import 'package:order_manager/models/app_user.dart';

abstract class AppUserRepository {
  Future<void> saveUser(AppUser user);
  Future<void> deleteUser(String id);
  Future<AppUser?> queryById(String id);
  Future<AppUser?> queryByEmail(String email);
  Stream<List<AppUser>> watchBusinessUsers(String businessId);
}
