import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/utils/quick_order_cart.dart';

Item fakeItem(String name) => Item(id: name, name: name, price: 10);

Type1 fakeType(String type) => Type1(id: type, type: type, price: 0);

Table1 fakeTable() => Table1(id: "1", tableNo: 1);

Order fakeOrder(String name) {
  return Order(
    id: name,
    item: fakeItem(name),
    table: fakeTable(),
    type: fakeType("Regular"),
    quantity: 0,
    status: "pending",
    note: "",
    amount: 0,
  );
}

void main() {
  late ProviderContainer container;
  late QuickOrderCart notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(quickOrderCartProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test("Initial state is empty", () {
    final state = container.read(quickOrderCartProvider);
    expect(state, isEmpty);
  });

  test("Increment adds order with quantity 1", () {
    final order = fakeOrder("Coffee");

    notifier.increment(order);

    final state = container.read(quickOrderCartProvider);

    expect(state.length, 1);
    expect(state.values.first.quantity, 1);
  });

  test("Multiple increments increase quantity", () {
    final order = fakeOrder("Coffee");

    notifier.increment(order);
    notifier.increment(order);
    notifier.increment(order);

    final state = container.read(quickOrderCartProvider);

    expect(state.values.first.quantity, 3);
  });

  test("Decrement reduces quantity", () {
    final order = fakeOrder("Coffee");

    notifier.increment(order);
    notifier.increment(order);

    notifier.decrement(order);

    final state = container.read(quickOrderCartProvider);

    expect(state.values.first.quantity, 1);
  });

  test("Decrement removes order when quantity becomes zero", () {
    final order = fakeOrder("Coffee");

    notifier.increment(order);
    notifier.decrement(order);

    final state = container.read(quickOrderCartProvider);

    expect(state, isEmpty);
  });

  test("getOrders returns list of orders", () {
    final order1 = fakeOrder("Coffee");
    final order2 = fakeOrder("Burger");

    notifier.increment(order1);
    notifier.increment(order2);

    final orders = notifier.getOrders();

    expect(orders.length, 2);
  });

  test("clear resets state to empty", () {
    final order = fakeOrder("Coffee");

    notifier.increment(order);

    notifier.clear();

    final state = container.read(quickOrderCartProvider);

    expect(state, isEmpty);
  });
}
