import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/type_providers.dart';
import '../test_helper.dart';

ProviderContainer createContainer({
  required MockTypeRepository typeRepo,
  required MockOrderRepository ordersRepo,
}) {
  return ProviderContainer(
    overrides: [
      typeRepositoryProvider.overrideWithValue(typeRepo),
      orderRepositoryProvider.overrideWithValue(ordersRepo),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeType1());
    registerFallbackValue(FakeOrder());
  });

  test('saving new type does not update orders', () async {
    final typeRepo = MockTypeRepository();
    final ordersRepo = MockOrderRepository();
    when(() => typeRepo.saveType(any())).thenAnswer((_) async {});

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    final newType = Type1(id: '', type: 'Extra', price: 20);

    await vm.saveType(newType);

    verify(() => typeRepo.saveType(newType)).called(1);
    verifyNever(() => typeRepo.getTypeById(any()));
    verifyNever(() => ordersRepo.saveOrders(any()));
  });

  test('updating existing type updates related orders', () async {
    final oldType = Type1(id: 't1', type: 'Extra', price: 20);
    final newType = Type1(id: 't1', type: 'Extra', price: 40);

    final typeRepo = MockTypeRepository();
    final ordersRepo = MockOrderRepository();

    when(() => typeRepo.getTypeById("t1")).thenAnswer((_) async => oldType);
    when(() => typeRepo.saveType(any())).thenAnswer((_) async {});

    final item = Item(id: 'i1', name: 'Burger', price: 100);
    final table = Table1(id: 'tb1', tableNo: 1);

    final order = Order(
      id: 'o1',
      quantity: 2,
      item: item,
      table: table,
      type: oldType,
      status: 'open',
      note: '',
      amount: 240,
    );

    when(() => ordersRepo.saveOrders(any())).thenAnswer((_) async {});
    when(
      () => ordersRepo.getOrdersByType(any()),
    ).thenAnswer((_) async => [order]);

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.saveType(newType);

    verify(() => ordersRepo.saveOrders(any())).called(1);
  });

  test('order amount is recalculated when type price changes', () async {
    final oldType = Type1(id: 't1', type: 'Extra', price: 10);
    final newType = Type1(id: 't1', type: 'Extra', price: 30);

    final typeRepo = MockTypeRepository();
    final ordersRepo = MockOrderRepository();

    when(() => typeRepo.getTypeById("t1")).thenAnswer((_) async => oldType);
    when(() => typeRepo.saveType(any())).thenAnswer((_) async {});

    final item = Item(id: 'i1', name: 'Burger', price: 100);
    final table = Table1(id: 'tb1', tableNo: 1);

    final order = Order(
      id: 'o1',
      quantity: 3,
      item: item,
      table: table,
      type: oldType,
      status: 'open',
      note: '',
      amount: 0,
    );

    when(
      () => ordersRepo.getOrdersByType(any()),
    ).thenAnswer((_) async => [order]);
    when(() => ordersRepo.saveOrders(any())).thenAnswer((_) async {});

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.saveType(newType);

    final captured =
        (verify(() => ordersRepo.saveOrders(captureAny())).captured.single
                as List<Order>)
            .first;
    final expected = (item.price + newType.price) * order.quantity;

    expect(captured.amount, expected);
    expect(captured.type, newType);
  });

  test(
    'updating type should not update orders if there are no orders',
    () async {
      final typeRepo = MockTypeRepository();
      final ordersRepo = MockOrderRepository();

      when(
        () => typeRepo.getTypeById("ty1"),
      ).thenAnswer((_) async => Type1(id: 'ty1', type: 'Extra', price: 100));
      when(() => typeRepo.saveType(any())).thenAnswer((_) async {});
      when(() => ordersRepo.getOrdersByType(any())).thenAnswer((_) async => []);

      final container = createContainer(
        typeRepo: typeRepo,
        ordersRepo: ordersRepo,
      );
      final vm = container.read(typesViewModelProvider.notifier);
      await vm.saveType(Type1(id: 'ty1', type: 'Extra New', price: 100));
      verifyNever(() => ordersRepo.saveOrder(any()));
    },
  );

  test('orders with different type are not updated', () async {
    final typeRepo = MockTypeRepository();
    final ordersRepo = MockOrderRepository();

    when(
      () => typeRepo.getTypeById("t1"),
    ).thenAnswer((_) async => Type1(id: 't1', type: 'Extra', price: 10));
    when(() => typeRepo.saveType(any())).thenAnswer((_) async {});
    when(() => ordersRepo.getOrdersByType(any())).thenAnswer((_) async => []);

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.saveType(Type1(id: 't1', type: 'Extra', price: 20));

    verifyNever(() => ordersRepo.saveOrder(any()));
  });

  test('deleteType delegates to repository when no orders exist', () async {
    final type = Type1(id: 't1', type: 'Extra', price: 20);

    final typeRepo = MockTypeRepository();
    final ordersRepo = MockOrderRepository();

    when(() => typeRepo.deleteType(any())).thenAnswer((_) async {});
    when(() => ordersRepo.getOrdersByType(any())).thenAnswer((_) async => []);

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    final result = await vm.deleteType(type);

    expect(result, true);
    verify(() => typeRepo.deleteType(type)).called(1);
  });

  test(
    'deleteType does not delegate to repository when orders exist',
    () async {
      final type = Type1(id: 't1', type: 'Extra', price: 20);

      final typeRepo = MockTypeRepository();
      final ordersRepo = MockOrderRepository();

      when(() => typeRepo.deleteType(any())).thenAnswer((_) async {});
      when(
        () => ordersRepo.getOrdersByType(any()),
      ).thenAnswer((_) async => [baseOrder(type: type)]);

      final container = createContainer(
        typeRepo: typeRepo,
        ordersRepo: ordersRepo,
      );

      final vm = container.read(typesViewModelProvider.notifier);

      final result = await vm.deleteType(type);

      expect(result, false);
      verifyNever(() => typeRepo.deleteType(any()));
    },
  );
}
