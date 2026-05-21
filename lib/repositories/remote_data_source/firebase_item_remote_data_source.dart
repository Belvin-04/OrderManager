import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/item_remote_data_source.dart';

class FirebaseItemRemoteDataSource implements ItemRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> itemsRef;
  final String businessId;

  FirebaseItemRemoteDataSource(this.itemsRef, {required this.businessId});

  @override
  Stream<Object?> watchItems() {
    return itemsRef.where('businessId', isEqualTo: businessId).snapshots().map((
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
  Future<Object?> queryById(String id) async {
    final result = await itemsRef.doc(id).get();
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
    return itemsRef.doc().id;
  }

  @override
  Future<void> save(String id, Map<String, dynamic> data) {
    return itemsRef.doc(id).set(data);
  }

  @override
  Future<void> delete(String id) {
    return itemsRef.doc(id).delete();
  }

  @override
  Future<bool> hasItems() async {
    final result = await itemsRef
        .where('businessId', isEqualTo: businessId)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }
}
