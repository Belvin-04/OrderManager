import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/viewmodels/order_viewmodel.dart';

class FakeOrdersViewModel extends OrdersViewModel {
  bool repeatCalled = false;
  bool restoreCalled = false;

  bool repeatResult = true;
  bool restoreResult = true;

  Order? restoredOrder;
  Order? repeatedOrder;
  Order? completedOrder;
  Order? canceledOrder;
  Order? savedOrder;

  final Stream<int>? stream;

  bool? createSplitResult;

  String? splitTableKey;

  final List<String> clearedSplits = [];
  final List<Order> splitChanged = [];
  bool removeSplitCalled = false;
  bool splitRemovedresult;
  String? removedSplitTableOrders;

  FakeOrdersViewModel({this.stream, this.splitRemovedresult = true});

  @override
  Future<void> restoreOrder(Order order) async {
    restoredOrder = order;
  }

  @override
  Future<void> repeatOrder(Order order) async {
    repeatedOrder = order;
  }

  @override
  Future<void> completeOrder(Order order) async {
    completedOrder = order;
  }

  @override
  Future<void> saveOrder(Order order, {bool isSplitOrder = false}) async {
    savedOrder = order;
  }

  @override
  Future<void> cancelOrder(Order order) async {
    canceledOrder = order;
  }

  @override
  Future<bool> repeatAllOrders(Table1 table) async {
    repeatCalled = true;
    return repeatResult;
  }

  @override
  Future<bool> restoreAllOrders(Table1 table) async {
    restoreCalled = true;
    return restoreResult;
  }

  @override
  Stream<int> getTotalAmountForTable(String tableKey, {String splitNo = "0"}) {
    return stream!;
  }

  @override
  Future<bool> createSplitOrders(String tableNo) async {
    splitTableKey = tableNo;
    return true;
  }

  @override
  Future<bool> removeSplitOrdersForTable(String tableKey) async {
    removeSplitCalled = true;
    removedSplitTableOrders = tableKey;
    return splitRemovedresult;
  }

  @override
  Future<bool> resetSplitNo(String tableKey, String splitNo) async {
    clearedSplits.add(splitNo);
    return true;
  }

  @override
  Future<bool> changeOrderSplitNo(Order order, int splitNo) async {
    splitChanged.add(order);
    return true;
  }
}
