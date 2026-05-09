import 'package:order_manager/models/app_user.dart';
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
  Stream<List<AppUser>> watchBusinessUsers(String businessId) {
    return remote.watchBusinessUsers(businessId).map((data) {
      if (data == null) return <AppUser>[];
      final map = data as Map<String, dynamic>;
      return map.values
          .map((e) => AppUser.fromMap(Map<String, dynamic>.from(e)))
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
}
