import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/viewmodels/items_viewmodel.dart';

import 'fake_repositories/fake_items_repository.dart';
import 'fake_repositories/fake_orders_repository.dart';

ProviderContainer createContainer({
  required FakeItemsRepository itemsRepo,
  required FakeOrdersRepository ordersRepo,
}) {
  return ProviderContainer(
    overrides: [
      itemRepositoryProvider.overrideWithValue(itemsRepo),
      orderRepositoryProvider.overrideWithValue(ordersRepo),
    ],
  );
}

void main() {
  test('saving new item does not update orders', () async {
    final itemsRepo = FakeItemsRepository();
    final ordersRepo = FakeOrdersRepository();

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    final newItem = Item(id: '', name: 'Burger', price: 100);

    await vm.saveItem(newItem);

    expect(ordersRepo.savedOrders, isEmpty);
  });

  test('updating existing item updates related orders', () async {
    final oldItem = Item(id: 'i1', name: 'Burger', price: 100);
    final newItem = Item(id: 'i1', name: 'Burger', price: 150);

    final itemsRepo = FakeItemsRepository()..items = [oldItem];

    final table = Table1(id: 't1', tableNo: 1);
    final type = Type1(id: 'ty1', type: 'Extra', price: 20);

    final order = Order(
      id: 'o1',
      quantity: 2,
      item: oldItem,
      table: table,
      type: type,
      status: 'open',
      note: '',
      amount: 240,
    );

    final ordersRepo = FakeOrdersRepository()..orders.add(order);

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    await vm.saveItem(newItem);

    expect(ordersRepo.savedOrders.length, 1);
  });

  test('order amount is recalculated correctly', () async {
    final oldItem = Item(id: 'i1', name: 'Burger', price: 100);
    final newItem = Item(id: 'i1', name: 'Burger', price: 200);

    final itemsRepo = FakeItemsRepository()..items = [oldItem];

    final table = Table1(id: 't1', tableNo: 1);
    final type = Type1(id: 'ty1', type: 'Extra', price: 30);

    final order = Order(
      id: 'o1',
      quantity: 3,
      item: oldItem,
      table: table,
      type: type,
      status: 'open',
      note: '',
      amount: 0,
    );

    final ordersRepo = FakeOrdersRepository()..orders.add(order);

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    await vm.saveItem(newItem);

    final updated = ordersRepo.savedOrders.first;
    final expected = (newItem.price + type.price) * order.quantity;

    expect(updated.amount, expected);
  });

  test('updated orders reference new item', () async {
    final oldItem = Item(id: 'i1', name: 'Burger', price: 100);
    final newItem = Item(id: 'i1', name: 'Burger', price: 180);

    final itemsRepo = FakeItemsRepository()..items = [oldItem];

    final table = Table1(id: 't1', tableNo: 1);
    final type = Type1(id: 'ty1', type: 'None', price: 0);

    final order = Order(
      id: 'o1',
      quantity: 1,
      item: oldItem,
      table: table,
      type: type,
      status: 'open',
      note: '',
      amount: 100,
    );

    final ordersRepo = FakeOrdersRepository()..orders.add(order);

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    await vm.saveItem(newItem);

    final updated = ordersRepo.savedOrders.first;
    expect(updated.item, newItem);
  });

  test(
    'updating item should not update orders if there are no orders',
    () async {
      final item = Item(id: 'i1', name: 'Burger', price: 100);
      final newItem = Item(id: 'i1', name: 'Burger New', price: 100);
      final itemsRepo = FakeItemsRepository()..items = [item];
      final ordersRepo = FakeOrdersRepository();
      final container = createContainer(
        itemsRepo: itemsRepo,
        ordersRepo: ordersRepo,
      );
      final vm = container.read(itemsViewModelProvider.notifier);
      await vm.saveItem(newItem);
      expect(ordersRepo.savedOrders, isEmpty);
    },
  );

  test('no related orders results in no updates', () async {
    final item = Item(id: 'i1', name: 'Burger', price: 100);
    final updatedItem = Item(id: 'i1', name: 'Burger', price: 150);
    final differentItem = Item(id: 'i2', name: 'Burger New', price: 100);

    final itemsRepo = FakeItemsRepository()..items = [item];

    final table = Table1(id: 't1', tableNo: 1);
    final type = Type1(id: 'ty1', type: 'None', price: 0);

    final order = Order(
      id: 'o1',
      quantity: 1,
      item: differentItem,
      table: table,
      type: type,
      status: 'open',
      note: '',
      amount: 100,
    );

    final ordersRepo = FakeOrdersRepository()..orders.add(order);

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    await vm.saveItem(updatedItem);

    expect(ordersRepo.savedOrders, isEmpty);
  });
}
