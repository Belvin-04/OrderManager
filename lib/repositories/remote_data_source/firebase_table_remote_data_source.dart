import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/table_remote_data_source.dart';

class FirebaseTableRemoteDataSource implements TableRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> tablesRef;
  final String businessId;

  FirebaseTableRemoteDataSource(this.tablesRef, {required this.businessId});

  @override
  Stream<Object?> watchTables() {
    return tablesRef.where('businessId', isEqualTo: businessId).snapshots().map(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }

        final map = <String, dynamic>{};
        for (final doc in snapshot.docs) {
          map[doc.id] = doc.data();
        }
        return map;
      },
    );
  }

  @override
  Future<Object?> getLastTable() async {
    final query = await tablesRef
        .where('businessId', isEqualTo: businessId)
        .where('tableNo', isGreaterThanOrEqualTo: 0)
        .orderBy('tableNo', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    final doc = query.docs.first;
    return {doc.id: doc.data()};
  }

  @override
  Future<String> generateId() async {
    return tablesRef.doc().id;
  }

  @override
  Future<void> save(String id, Map<String, dynamic> data) {
    return tablesRef.doc(id).set(data);
  }

  @override
  Future<void> delete(String id) {
    return tablesRef.doc(id).delete();
  }

  @override
  Future<void> updatePosition(String id, Map<String, dynamic> pos) {
    return tablesRef.doc(id).update({'position': pos});
  }
}
