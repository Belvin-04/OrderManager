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
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    Map<String, dynamic>? lastData;
    int? lastNo;
    String? lastId;
    for (final doc in query.docs) {
      final data = doc.data();
      final tableNo = data['tableNo'];
      if (tableNo is! int) {
        continue;
      }
      if (lastNo == null || tableNo > lastNo) {
        lastNo = tableNo;
        lastData = data;
        lastId = doc.id;
      }
    }

    if (lastData == null || lastId == null) {
      return null;
    }
    return {lastId: lastData};
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
