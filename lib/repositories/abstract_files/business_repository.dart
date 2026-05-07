import 'package:order_manager/models/business.dart';

abstract class BusinessRepository {
  Stream<List<Business>> watchBusiness();
  Future<Business> saveBusiness(Business business);
  Future<void> deleteBusiness(Business business);
  Future<void> deleteBusinessCollections(String businessId);
}
