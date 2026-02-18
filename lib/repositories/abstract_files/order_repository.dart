import 'package:order_manager/models/order.dart';

abstract class OrderRepository {
  Stream<List<Order>> watchOrdersForTable(String tableKey);
  Future<bool> hasPendingOrdersForTable(String tableKey);
  Future<bool> hasAnyOrdersForTable(String tableKey);
  Future<void> deleteOrdersForTable(String tableKey);
  Stream<int> getTotalAmountForTable(String tableKey, {String splitNo});
  Future<List<Order>> getOrdersForTable(String tableKey);
  Future<List<Order>> getOrdersForSplitTable(String tableKey, String splitNo);
  Future<List<Order>> getOrdersByType(String typeName);
  Future<List<Order>> getOrdersByItem(String itemName);
  Future<Set<int>> getOccupiedTableNos();
  Future<void> moveOrders(String fromTableKey, String toTableKey);
  Future<void> saveOrder(Order order, {bool isSplit});
  Future<void> deleteOrder(Order order, {required bool isSplit});
  Stream<List<Order>> watchOrdersByStatus(String status, String tableNo);
  Stream<List<Order>> getBillOrdersForTable(String tableNo);
  Stream<List<Order>> watchSplitOrders(String tableNo);
  Stream<List<Order>> getSplitOrders(String tableNo);
  Future<bool> removeSplitOrdersForTable(String tableNo);
  Map<String, int> getBillTotals(List<Order> orders);
}
