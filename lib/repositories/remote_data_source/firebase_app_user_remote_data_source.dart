import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/app_user_remote_data_source.dart';

class FirebaseAppUserRemoteDataSource implements AppUserRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> usersRef;
  final CollectionReference<Map<String, dynamic>> businessUsersRef;

  FirebaseAppUserRemoteDataSource(this.usersRef, this.businessUsersRef);

  @override
  Future<void> saveUser(String id, Map<String, dynamic> data) async {
    return usersRef.doc(id).set(data);
  }

  @override
  Future<void> deleteUser(String id) async {
    return usersRef.doc(id).delete();
  }

  @override
  Future<Object?> queryById(String id) async {
    final result = await usersRef.doc(id).get();
    if (!result.exists) {
      return null;
    }

    final data = result.data();
    if (data == null) {
      return null;
    }
    return {result.id: data};
  }

  @override
  Stream<Object?> watchEmployedBusinesses(String userId) {
    return businessUsersRef
        .where('employeeId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          final map = <String, dynamic>{};
          for (final doc in snapshot.docs) {
            map[doc.id] = doc.data();
          }
          return map;
        });
  }

  @override
  Stream<Object?> watchBusinessEmployees(String businessId) {
    return businessUsersRef
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final map = <String, dynamic>{};
          for (final doc in snapshot.docs) {
            map[doc.id] = doc.data();
          }
          return map;
        });
  }

  @override
  Future<Object?> queryByEmail(String email) async {
    final result = await usersRef.where('email', isEqualTo: email).get();

    if (result.docs.isEmpty) {
      return null;
    }

    final map = <String, dynamic>{};
    for (final doc in result.docs) {
      final data = doc.data();
      if (data['email'] == email) {
        map[doc.id] = data;
      }
    }
    return map.isEmpty ? null : map;
  }

  @override
  Future<void> addBusinessEmployee(
    String relationId,
    Map<String, dynamic> data,
  ) {
    return businessUsersRef.doc(relationId).set(data);
  }

  @override
  Future<void> removeBusinessEmployee(String relationId) async {
    return businessUsersRef.doc(relationId).delete();
  }
}
