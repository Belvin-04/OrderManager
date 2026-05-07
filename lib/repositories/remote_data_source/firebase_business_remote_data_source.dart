import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/business_remote_data_source.dart';

class FirebaseBusinessRemoteDataSource implements BusinessRemoteDataSource {
  final FirebaseFirestore firestore;
  final CollectionReference<Map<String, dynamic>> businessesRef;
  final String ownerId;

  FirebaseBusinessRemoteDataSource(
    this.businessesRef, {
    required this.ownerId,
    required this.firestore,
  });

  @override
  Stream<Object?> watchBusiness() {
    return businessesRef.where('ownerId', isEqualTo: ownerId).snapshots().map((
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
  Future<void> save(String id, Map<String, dynamic> data) {
    return businessesRef.doc(id).set(data);
  }

  @override
  Future<void> delete(String id) async {
    await businessesRef.doc(id).delete();
  }

  @override
  Future<String> generateId() async {
    return businessesRef.doc().id;
  }

  @override
  Future<Object?> queryById(String id) async {
    final doc = await businessesRef.doc(id).get();
    if (!doc.exists) {
      return null;
    }

    final data = doc.data();
    if (data == null || data['ownerId'] != ownerId) {
      return null;
    }

    return {doc.id: data};
  }

  @override
  Future<void> deleteBusinessCollections(String businessId) async {
    const collections = ['items', 'types', 'tables', 'orders', 'split-orders'];
    const maxBatchSize = 450;

    for (final collection in collections) {
      final snapshot = await firestore
          .collection(collection)
          .where('businessId', isEqualTo: businessId)
          .get();

      if (snapshot.docs.isEmpty) {
        continue;
      }

      for (var i = 0; i < snapshot.docs.length; i += maxBatchSize) {
        final batch = firestore.batch();
        final chunk = snapshot.docs.skip(i).take(maxBatchSize);
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
  }
}
