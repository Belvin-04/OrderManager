import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'in_memory/in_memory_order_repository.dart';

final testTable = Table1(id: 't', tableNo: 1);

Order baseOrder({
  String id = '',
  int quantity = 1,
  String status = 'pending',
  int amount = 100,
  int splitNo = 0,
  Table1? table,
  Type1? type,
}) {
  return Order(
    id: id,
    quantity: quantity,
    item: Item(id: 'i', name: 'Burger', price: 100),
    type: type ?? Type1(id: 't', type: 'None', price: 0),
    table:
        table?.copyWith(splitNo: splitNo) ??
        testTable.copyWith(splitNo: splitNo),
    status: status,
    note: '',
    amount: amount,
  );
}

void main() {
  late InMemoryOrderRepository repo;

  setUp(() {
    repo = InMemoryOrderRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('saveOrder stores order and preserves amount', () async {
    final order = baseOrder(quantity: 2, amount: 200);

    await repo.saveOrder(order);

    final orders = await repo.getOrdersForTable('1');
    expect(orders.length, 1);
    expect(orders.first.amount, 200);
  });

  test('hasPendingOrdersForTable detects pending orders', () async {
    await repo.saveOrder(baseOrder());

    final result = await repo.hasPendingOrdersForTable('1');
    expect(result, true);
  });

  test('moveOrders moves all orders to new table', () async {
    await repo.saveOrder(baseOrder());
    await repo.moveOrders('1', '2');

    final orders = await repo.getOrdersForTable('2');
    expect(orders.length, 1);
  });

  test('getOccupiedTableNos returns unique table numbers', () async {
    await repo.saveOrder(baseOrder(id: 'o1'));
    await repo.saveOrder(
      baseOrder(
        id: 'o2',
        table: Table1(tableNo: 2, id: 't2'),
      ),
    );

    final tables = await repo.getOccupiedTableNos();
    expect(tables, {1, 2});
  });

  test('split orders are stored separately', () async {
    await repo.saveOrder(baseOrder(), isSplit: true);

    final splitOrders = await repo.getSplitOrders('1').first;
    expect(splitOrders.length, 1);
  });

  test('getBillTotals sums amount and quantity', () async {
    final orders = [baseOrder(quantity: 2, amount: 200), baseOrder()];

    final totals = repo.getBillTotals(orders);
    expect(totals['quantity'], 3);
    expect(totals['amount'], 300);
  });
}
