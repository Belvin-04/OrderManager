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

  Future<QuerySnapshot<Map<String, dynamic>>> _getBusinessOrders({
    required bool isSplit,
  }) {
    final ref = isSplit ? splitOrdersRef : ordersRef;
    return ref.where('businessId', isEqualTo: businessId).get();
  }

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
  Future<Object?> getAllOrders() async {
    final query = await _getBusinessOrders(isSplit: false);
    return _toMap(query);
  }

  @override
  Future<Object?> getSplitOrdersByTable(int tableNo) async {
    final query = await _getBusinessOrders(isSplit: true);
    final map = _toMap(query);
    if (map == null) {
      return null;
    }

    final filtered = <String, dynamic>{};
    for (final entry in map.entries) {
      final table = entry.value['table'];
      if (table is Map && table['tableNo'] == tableNo) {
        filtered[entry.key] = entry.value;
      }
    }

    return filtered.isEmpty ? null : filtered;
  }

  @override
  Future<Object?> queryOrdersByItem(String item) async {
    final query = await _getBusinessOrders(isSplit: false);
    final map = _toMap(query);
    if (map == null) {
      return null;
    }

    final filtered = <String, dynamic>{};
    for (final entry in map.entries) {
      final itemMap = entry.value['item'];
      if (itemMap is Map && itemMap['name'] == item) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered.isEmpty ? null : filtered;
  }

  @override
  Future<Object?> queryOrdersByTable(int tableNo) async {
    final query = await _getBusinessOrders(isSplit: false);
    final map = _toMap(query);
    if (map == null) {
      return null;
    }

    final filtered = <String, dynamic>{};
    for (final entry in map.entries) {
      final table = entry.value['table'];
      if (table is Map && table['tableNo'] == tableNo) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered.isEmpty ? null : filtered;
  }

  @override
  Future<Object?> queryOrdersByType(String type) async {
    final query = await _getBusinessOrders(isSplit: false);
    final map = _toMap(query);
    if (map == null) {
      return null;
    }

    final filtered = <String, dynamic>{};
    for (final entry in map.entries) {
      final typeMap = entry.value['type'];
      if (typeMap is Map && typeMap['type'] == type) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered.isEmpty ? null : filtered;
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
  Stream<Object?> watchOrders() {
    return ordersRef
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map(_toMap);
  }

  @override
  Stream<Object?> watchSplitOrders() {
    return splitOrdersRef
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map(_toMap);
  }
}
