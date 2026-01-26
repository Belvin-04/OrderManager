import 'package:firebase_database/firebase_database.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/table_remote_data_source.dart';

class FirebaseTableRemoteDataSource implements TableRemoteDataSource {
  final DatabaseReference ref;

  FirebaseTableRemoteDataSource(this.ref);

  @override
  Stream<Object?> watchTables() => ref.onValue.map((e) => e.snapshot.value);

  @override
  Future<Object?> getLastTable() async {
    final query = ref.orderByChild('tableNo').limitToLast(1);
    final event = await query.once();
    return event.snapshot.value;
  }

  @override
  Future<String> generateId() async {
    return ref.push().key!;
  }

  @override
  Future<void> save(String id, Map<String, dynamic> data) {
    return ref.child(id).set(data);
  }

  @override
  Future<void> delete(String id) {
    return ref.child(id).remove();
  }

  @override
  Future<void> updatePosition(String id, Map<String, dynamic> pos) {
    return ref.child(id).child('position').update(pos);
  }
}
