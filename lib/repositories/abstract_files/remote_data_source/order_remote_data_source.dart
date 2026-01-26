abstract class OrderRemoteDataSource {
  Stream<Object?> watchOrders();
  Stream<Object?> watchSplitOrders();
  Future<Object?> getAllOrders();
  Future<Object?> queryOrdersByTable(int tableNo);
  Future<Object?> queryOrdersByType(String type);
  Future<Object?> queryOrdersByItem(String item);
  Future<Object?> getSplitOrdersByTable(int tableNo);
  Future<String> generateId({required bool isSplit});
  Future<void> save(
    String id,
    Map<String, dynamic> data, {
    required bool isSplit,
  });
  Future<void> delete(String id, {required bool isSplit});
  Future<void> updateTableNo(String id, int tableNo);
}
