import 'package:order_manager/models/order.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';

class FakeOrdersRepository implements OrderRepository {
  final List<Order> orders = [];
  List<Order> splitOrders = [];
  List<Order> splitOrdersSaved = [];
  final List<Order> savedOrders = [];
  String? deletedOrdersForTable;
  Map<String, String>? movedOrders;

  @override
  Future<List<Order>> getOrdersByItem(String itemName) async {
    return orders.where((o) => o.item.name == itemName).toList();
  }

  @override
  Future<void> saveOrder(Order order, {bool isSplit = false}) async {
    if (isSplit) {
      splitOrdersSaved.add(order);
    } else {
      savedOrders.add(order);
    }
  }

  @override
  Future<void> deleteOrder(Order order, {required bool isSplit}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteOrdersForTable(String tableKey) async {
    orders.removeWhere((o) => o.table.tableNo.toString() == tableKey);
    deletedOrdersForTable = tableKey;
  }

  @override
  Stream<List<Order>> getBillOrdersForTable(String tableNo) async* {
    yield orders.where((o) => o.table.tableNo.toString() == tableNo).toList();
  }

  @override
  Map<String, int> getBillTotals(List<Order> orders) {
    int totalAmount = 0;
    int totalQuantity = 0;

    for (final o in orders) {
      totalAmount += o.amount;
      totalQuantity += o.quantity;
    }

    return {'amount': totalAmount, 'quantity': totalQuantity};
  }

  @override
  Future<Set<int>> getOccupiedTableNos() async {
    return orders.map((o) => o.table.tableNo).toSet();
  }

  @override
  Future<List<Order>> getOrdersByType(String typeName) async {
    return orders.where((o) => o.type.type == typeName).toList();
  }

  @override
  Future<List<Order>> getOrdersForTable(String tableKey) async {
    return orders.where((o) => o.table.tableNo.toString() == tableKey).toList();
  }

  @override
  Stream<List<Order>> getSplitOrders(String tableNo) async* {
    yield splitOrders
        .where((o) => o.table.tableNo.toString() == tableNo)
        .toList();
  }

  @override
  Stream<int> getTotalAmountForTable(String tableKey, {String splitNo = "0"}) {
    return Stream.value(250);
  }

  @override
  Future<bool> hasAnyOrdersForTable(String tableKey) async {
    return orders.any((o) => o.table.tableNo.toString() == tableKey);
  }

  @override
  Future<bool> hasPendingOrdersForTable(String tableKey) async {
    return orders.any(
      (o) => o.table.tableNo.toString() == tableKey && o.status == 'pending',
    );
  }

  @override
  Future<void> moveOrders(String from, String to) async {
    movedOrders = {'from': from, 'to': to};
  }

  @override
  Future<bool> removeSplitOrdersForTable(String tableNo) async {
    try {
      splitOrders.removeWhere((o) => o.table.tableNo.toString() == tableNo);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<List<Order>> watchOrdersByStatus(
    String status,
    String tableNo,
  ) async* {
    yield orders
        .where(
          (o) => o.status == status && o.table.tableNo.toString() == tableNo,
        )
        .toList();
  }

  @override
  Stream<List<Order>> watchSplitOrders(String tableNo) {
    return Stream.value(
      splitOrders.where((o) => o.table.tableNo.toString() == tableNo).toList(),
    );
  }
}
