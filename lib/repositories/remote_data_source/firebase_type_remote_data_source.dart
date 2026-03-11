import 'package:firebase_database/firebase_database.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/type_remote_data_source.dart';

class FirebaseTypeRemoteDataSource implements TypeRemoteDataSource {
  final DatabaseReference ref;

  FirebaseTypeRemoteDataSource(this.ref);

  @override
  Stream<Object?> watchTypes() {
    return ref.onValue.map((e) => e.snapshot.value);
  }

  @override
  Future<Object?> queryByType(String type) async {
    final result = await ref.orderByChild('type').equalTo(type).once();
    return result.snapshot.value;
  }

  @override
  Future<Object?> queryById(String id) async {
    final result = await ref.orderByChild('id').equalTo(id).once();
    return result.snapshot.value;
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
}
