abstract class OrderRemoteDataSource {
  Stream<Object?> watchOrders({
    required List<String> fields,
    required List<Object> values,
    required List<bool> isEqualTo,
    bool isSplit = false,
    bool limitToOne = false,
  });
  Future<String> generateId({required bool isSplit});
  Future<void> save(
    String id,
    Map<String, dynamic> data, {
    required bool isSplit,
  });
  Future<void> delete(String id, {required bool isSplit});
  Future<void> updateAllTableNo(List<String> ids, int tableNo);
  Future<Object?> getOrdersBy({
    required List<String> fields,
    required List<Object> values,
    required List<bool> isEqualTo,
    bool limitToOne = false,
    bool isSplit = false,
  });
  Future<void> saveAll(
    Map<String, Map<String, dynamic>> idToData, {
    required bool isSplit,
  });
  Future<void> deleteAll(List<String> ids, {required bool isSplit});
}
