import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/type_remote_data_source.dart';

class FirebaseTypeRemoteDataSource implements TypeRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> typesRef;
  final String businessId;

  FirebaseTypeRemoteDataSource(this.typesRef, {required this.businessId});

  @override
  Stream<Object?> watchTypes() {
    return typesRef.where('businessId', isEqualTo: businessId).snapshots().map((
      snapshot,
    ) {
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
  Future<Object?> queryByType(String type) async {
    final result = await typesRef
        .where('businessId', isEqualTo: businessId)
        .where('type', isEqualTo: type)
        .get();

    if (result.docs.isEmpty) {
      return null;
    }

    final map = <String, dynamic>{};
    for (final doc in result.docs) {
      map[doc.id] = doc.data();
    }
    return map.isEmpty ? null : map;
  }

  @override
  Future<Object?> queryById(String id) async {
    final result = await typesRef.doc(id).get();
    if (!result.exists) {
      return null;
    }

    final data = result.data();
    if (data == null || data['businessId'] != businessId) {
      return null;
    }
    return {result.id: data};
  }

  @override
  Future<String> generateId() async {
    return typesRef.doc().id;
  }

  @override
  Future<void> save(String id, Map<String, dynamic> data) {
    return typesRef.doc(id).set(data);
  }

  @override
  Future<void> delete(String id) {
    return typesRef.doc(id).delete();
  }
}
