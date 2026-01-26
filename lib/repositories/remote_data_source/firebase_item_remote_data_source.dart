import 'package:firebase_database/firebase_database.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/item_remote_data_source.dart';

class FirebaseItemRemoteDataSource implements ItemRemoteDataSource {
  final DatabaseReference ref;

  FirebaseItemRemoteDataSource(this.ref);

  @override
  Stream<Object?> watchItems() => ref.onValue.map((e) => e.snapshot.value);

  @override
  Future<Object?> queryByName(String name) async {
    final result = await ref.orderByChild('name').equalTo(name).once();
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
