import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/order_remote_data_source.dart';

class FirebaseOrderRemoteDataSource implements OrderRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> ordersRef;
  final CollectionReference<Map<String, dynamic>> splitOrdersRef;
  final String businessId;

  FirebaseOrderRemoteDataSource(
    this.ordersRef,
    this.splitOrdersRef, {
    required this.businessId,
  });

  Map<String, dynamic>? _toMap(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.docs.isEmpty) {
      return null;
    }

    final map = <String, dynamic>{};
    for (final doc in snapshot.docs) {
      map[doc.id] = doc.data();
    }
    return map;
  }

  @override
  Future<Object?> getOrdersBy({
    required List<String> fields,
    required List<Object> values,
    required List<bool> isEqualTo,
    bool limitToOne = false,
    bool isSplit = false,
  }) async {
    final ref = isSplit ? splitOrdersRef : ordersRef;
    var query = ref.where('businessId', isEqualTo: businessId);

    if (fields.isNotEmpty &&
        values.isNotEmpty &&
        fields.length == values.length &&
        isEqualTo.length == fields.length) {
      for (int i = 0; i < fields.length; i++) {
        query = isEqualTo[i]
            ? query.where(fields[i], isEqualTo: values[i])
            : query.where(fields[i], isNotEqualTo: values[i]);
      }
    }

    if (limitToOne) {
      query = query.limit(1);
    }

    final snap = await query.get();
    return _toMap(snap);
  }

  @override
  Future<void> delete(String id, {required bool isSplit}) async {
    final dbRef = isSplit ? splitOrdersRef : ordersRef;
    await dbRef.doc(id).delete();
  }

  @override
  Future<String> generateId({required bool isSplit}) async {
    final dbRef = isSplit ? splitOrdersRef : ordersRef;
    return dbRef.doc().id;
  }

  @override
  Future<void> save(
    String id,
    Map<String, dynamic> data, {
    required bool isSplit,
  }) async {
    final dbRef = isSplit ? splitOrdersRef : ordersRef;
    await dbRef.doc(id).set(data);
  }

  @override
  Future<void> updateTableNo(String id, int tableNo) async {
    return ordersRef.doc(id).update({'table.tableNo': tableNo});
  }

  @override
  Stream<Object?> watchOrders({
    required List<String> fields,
    required List<Object> values,
    required List<bool> isEqualTo,
    bool isSplit = false,
  }) {
    final ref = isSplit ? splitOrdersRef : ordersRef;
    var query = ref.where('businessId', isEqualTo: businessId);

    if (fields.isNotEmpty &&
        values.isNotEmpty &&
        fields.length == values.length &&
        isEqualTo.length == fields.length) {
      for (int i = 0; i < fields.length; i++) {
        query = isEqualTo[i]
            ? query.where(fields[i], isEqualTo: values[i])
            : query.where(fields[i], isNotEqualTo: values[i]);
      }
    }

    return query.snapshots().map(_toMap);
  }
}
