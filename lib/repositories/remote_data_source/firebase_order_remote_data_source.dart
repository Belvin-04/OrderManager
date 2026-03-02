import 'package:firebase_database/firebase_database.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/order_remote_data_source.dart';

class FirebaseOrderRemoteDataSource implements OrderRemoteDataSource {
  final DatabaseReference ref;
  final DatabaseReference splitRef;

  FirebaseOrderRemoteDataSource(this.ref, this.splitRef);

  @override
  Future<void> delete(String id, {required bool isSplit}) async {
    final dbRef = isSplit ? splitRef : ref;
    await dbRef.child(id).remove();
  }

  @override
  Future<String> generateId({required bool isSplit}) async {
    final dbRef = isSplit ? splitRef : ref;
    return dbRef.push().key!;
  }

  @override
  Future<Object?> getAllOrders() async {
    final event = await ref.once();
    return event.snapshot.value;
  }

  @override
  Future<Object?> getSplitOrdersByTable(int tableNo) async {
    final query = splitRef.orderByChild("table/tableNo").equalTo(tableNo);
    final snapshot = await query.get();
    return snapshot.value;
  }

  @override
  Future<Object?> queryOrdersByItem(String item) async {
    final query = ref.orderByChild("item/name").equalTo(item);
    final event = await query.once();
    return event.snapshot.value;
  }

  @override
  Future<Object?> queryOrdersByTable(int tableNo) async {
    final query = ref.orderByChild('table/tableNo').equalTo(tableNo);
    final event = await query.once();
    return event.snapshot.value;
  }

  @override
  Future<Object?> queryOrdersByType(String type) async {
    final query = ref.orderByChild("type/type").equalTo(type);
    final event = await query.once();
    return event.snapshot.value;
  }

  @override
  Future<void> save(
    String id,
    Map<String, dynamic> data, {
    required bool isSplit,
  }) async {
    final dbRef = isSplit ? splitRef : ref;
    await dbRef.child(id).set(data);
  }

  @override
  Future<void> updateTableNo(String id, int tableNo) async {
    return ref.child(id).update({'table/tableNo': tableNo});
  }

  @override
  Stream<Object?> watchOrders() {
    return ref.onValue.map((e) => e.snapshot.value);
  }

  @override
  Stream<Object?> watchSplitOrders() {
    return splitRef.onValue.map((e) => e.snapshot.value);
  }
}
