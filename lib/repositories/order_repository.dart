import 'package:order_manager/models/order.dart';

abstract class OrderRepository {
  Future<bool> hasPendingOrdersForTable(String tableKey);
  Future<bool> hasAnyOrdersForTable(String tableKey);
  Future<void> deleteOrdersForTable(String tableKey);
  Stream<int> getTotalAmountForTable(String tableKey);
  Future<List<Order>> getOrdersForTable(String tableKey);
  Future<List<Order>> getOrdersByType(String typeName);
  Future<Set<int>> getOccupiedTableNos();
  Future<void> moveOrders(String fromTableKey, String toTableKey);
  Future<void> saveOrder(Order order);
  Stream<List<Order>> watchOrdersByStatus(String status, String tableNo);
  Stream<List<Order>> getBillOrdersForTable(String tableNo);
  Map<String, int> getBillTotals(List<Order> orders);
}
