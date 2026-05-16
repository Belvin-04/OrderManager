import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/item_providers.dart';
import 'package:order_manager/providers/order_providers.dart';
import '../test_helper.dart';

ProviderContainer createContainer({
  required MockItemsRepository itemsRepo,
  required MockOrderRepository ordersRepo,
}) {
  return ProviderContainer(
    overrides: [
      itemRepositoryProvider.overrideWithValue(itemsRepo),
      orderRepositoryProvider.overrideWithValue(ordersRepo),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeItem());
    registerFallbackValue(FakeOrder());
  });

  test('saving new item does not update orders', () async {
    final itemsRepo = MockItemsRepository();
    final ordersRepo = MockOrderRepository();

    when(itemsRepo.watchItems).thenAnswer((_) => Stream.value([]));
    when(() => ordersRepo.getOrdersByItem(any())).thenAnswer((_) async => []);
    when(() => itemsRepo.getItem(any())).thenAnswer((_) async => null);
    when(() => itemsRepo.saveItem(any())).thenAnswer((_) async {});

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    final newItem = Item(id: '', name: 'Burger', price: 100);

    await vm.saveItem(newItem);

    verify(() => itemsRepo.saveItem(newItem)).called(1);
    verifyNever(() => ordersRepo.saveOrder(any()));
  });

  test('updating existing item updates related orders', () async {
    final oldItem = Item(id: 'i1', name: 'Burger', price: 100);
    final newItem = Item(id: 'i1', name: 'Burger', price: 150);

    final itemsRepo = MockItemsRepository();
    final ordersRepo = MockOrderRepository();

    when(itemsRepo.watchItems).thenAnswer((_) => Stream.value([oldItem]));
    when(() => itemsRepo.saveItem(any())).thenAnswer((_) async {});

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

    when(
      () => ordersRepo.getOrdersByItem(any()),
    ).thenAnswer((_) async => [order]);
    when(() => ordersRepo.saveOrder(any())).thenAnswer((_) async {});

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    await vm.saveItem(newItem);

    verify(() => ordersRepo.saveOrder(any())).called(1);
  });

  test('order amount is recalculated correctly', () async {
    final oldItem = Item(id: 'i1', name: 'Burger', price: 100);
    final newItem = Item(id: 'i1', name: 'Burger', price: 200);

    final itemsRepo = MockItemsRepository();
    final ordersRepo = MockOrderRepository();

    when(itemsRepo.watchItems).thenAnswer((_) => Stream.value([oldItem]));
    when(() => itemsRepo.saveItem(any())).thenAnswer((_) async {});

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

    when(
      () => ordersRepo.getOrdersByItem(any()),
    ).thenAnswer((_) async => [order]);
    when(() => ordersRepo.saveOrder(any())).thenAnswer((_) async {});

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    await vm.saveItem(newItem);

    final captured =
        verify(() => ordersRepo.saveOrder(captureAny())).captured.single
            as Order;

    final expected = (newItem.price + type.price) * order.quantity;

    expect(captured.amount, expected);
  });

  test('updated orders reference new item', () async {
    final oldItem = Item(id: 'i1', name: 'Burger', price: 100);
    final newItem = Item(id: 'i1', name: 'Burger', price: 180);

    final itemsRepo = MockItemsRepository();
    final ordersRepo = MockOrderRepository();

    when(itemsRepo.watchItems).thenAnswer((_) => Stream.value([oldItem]));
    when(() => itemsRepo.saveItem(any())).thenAnswer((_) async {});

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

    when(
      () => ordersRepo.getOrdersByItem(any()),
    ).thenAnswer((_) async => [order]);
    when(() => ordersRepo.saveOrder(any())).thenAnswer((_) async {});

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    await vm.saveItem(newItem);

    final captured =
        verify(() => ordersRepo.saveOrder(captureAny())).captured.single
            as Order;
    expect(captured.item, newItem);
  });

  test(
    'updating item should not update orders if there are no orders',
    () async {
      final item = Item(id: 'i1', name: 'Burger', price: 100);
      final newItem = Item(id: 'i1', name: 'Burger New', price: 100);

      final itemsRepo = MockItemsRepository();
      final ordersRepo = MockOrderRepository();

      when(itemsRepo.watchItems).thenAnswer((_) => Stream.value([item]));
      when(() => itemsRepo.saveItem(any())).thenAnswer((_) async {});
      when(() => ordersRepo.getOrdersByItem(any())).thenAnswer((_) async => []);

      final container = createContainer(
        itemsRepo: itemsRepo,
        ordersRepo: ordersRepo,
      );
      final vm = container.read(itemsViewModelProvider.notifier);
      await vm.saveItem(newItem);
      verifyNever(() => ordersRepo.saveOrder(any()));
    },
  );

  test('no related orders results in no updates', () async {
    final item = Item(id: 'i1', name: 'Burger', price: 100);
    final updatedItem = Item(id: 'i1', name: 'Burger', price: 150);

    final itemsRepo = MockItemsRepository();
    final ordersRepo = MockOrderRepository();

    when(itemsRepo.watchItems).thenAnswer((_) => Stream.value([item]));
    when(() => itemsRepo.saveItem(any())).thenAnswer((_) async {});

    when(() => ordersRepo.getOrdersByItem(any())).thenAnswer((_) async => []);

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(itemsViewModelProvider.notifier);

    await vm.saveItem(updatedItem);

    verifyNever(() => ordersRepo.saveOrder(any()));
  });

  test('deleteItem delegates to repository when no orders exist', () async {
    final item = Item(id: 'i1', name: 'Burger', price: 100);

    final itemsRepo = MockItemsRepository();
    final ordersRepo = MockOrderRepository();

    when(() => itemsRepo.deleteItem(any())).thenAnswer((_) async {});
    when(() => ordersRepo.getOrdersByItem(any())).thenAnswer((_) async => []);

    final container = createContainer(
      itemsRepo: itemsRepo,
      ordersRepo: ordersRepo,
    );
    final vm = container.read(itemsViewModelProvider.notifier);

    final result = await vm.deleteItem(item);

    expect(result, true);
    verify(() => itemsRepo.deleteItem(item)).called(1);
  });

  test(
    'deleteItem does not delegate to repository when orders exist',
    () async {
      final item = Item(id: 'i1', name: 'Burger', price: 100);

      final itemsRepo = MockItemsRepository();
      final ordersRepo = MockOrderRepository();

      when(() => itemsRepo.deleteItem(any())).thenAnswer((_) async {});
      when(
        () => ordersRepo.getOrdersByItem(any()),
      ).thenAnswer((_) async => [baseOrder(item: item)]);

      final container = createContainer(
        itemsRepo: itemsRepo,
        ordersRepo: ordersRepo,
      );
      final vm = container.read(itemsViewModelProvider.notifier);

      final result = await vm.deleteItem(item);

      expect(result, false);
      verifyNever(() => itemsRepo.deleteItem(any()));
    },
  );
}
