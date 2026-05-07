import 'package:order_manager/models/business.dart';
import 'package:order_manager/repositories/abstract_files/business_repository.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/business_remote_data_source.dart';

class FirebaseBusinessRepository implements BusinessRepository {
  final BusinessRemoteDataSource remote;
  FirebaseBusinessRepository(this.remote);

  @override
  Future<Business> saveBusiness(Business business) async {
    String id = business.id.isEmpty ? await remote.generateId() : business.id;

    final Business newBusiness = business.copyWith(id: id);
    final data = newBusiness.toMap();

    await remote.save(id, data);
    return newBusiness;
  }

  @override
  Future<void> deleteBusiness(Business business) async {
    return remote.delete(business.id);
  }

  @override
  Stream<List<Business>> watchBusiness() {
    return remote.watchBusiness().map((data) {
      if (data == null) return <Business>[];

      final map = Map<String, dynamic>.from(data as Map);
      final businesses = map.values
          .map((e) => Business.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      businesses.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return businesses;
    });
  }

  @override
  Future<void> deleteBusinessCollections(String businessId) {
    return remote.deleteBusinessCollections(businessId);
  }
}
