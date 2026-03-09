import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/type_providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/type_repository.dart';

class MockTypeRepository extends Mock implements TypeRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class FakeType1 extends Fake implements Type1 {}

class FakeOrder extends Fake implements Order {}

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
    when(typeRepo.watchTypes).thenAnswer((_) => Stream.value([]));
    when(() => typeRepo.saveType(any())).thenAnswer((_) async {});

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    final newType = Type1(id: '', type: 'Extra', price: 20);

    await vm.saveType(newType);

    verify(() => typeRepo.saveType(newType)).called(1);
    verifyNever(() => ordersRepo.saveOrder(any()));
  });

  test('updating existing type updates related orders', () async {
    final oldType = Type1(id: 't1', type: 'Extra', price: 20);
    final newType = Type1(id: 't1', type: 'Extra', price: 40);

    final typeRepo = MockTypeRepository();
    final ordersRepo = MockOrderRepository();

    when(typeRepo.watchTypes).thenAnswer((_) => Stream.value([oldType]));
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

    when(() => ordersRepo.saveOrder(any())).thenAnswer((_) async {});
    when(
      () => ordersRepo.getOrdersByType(any()),
    ).thenAnswer((_) async => [order]);

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.saveType(newType);

    verify(() => ordersRepo.saveOrder(any())).called(1);
  });

  test('order amount is recalculated when type price changes', () async {
    final oldType = Type1(id: 't1', type: 'Extra', price: 10);
    final newType = Type1(id: 't1', type: 'Extra', price: 30);

    final typeRepo = MockTypeRepository();
    final ordersRepo = MockOrderRepository();

    when(typeRepo.watchTypes).thenAnswer((_) => Stream.value([oldType]));
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
    when(() => ordersRepo.saveOrder(any())).thenAnswer((_) async {});

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.saveType(newType);

    final captured =
        verify(() => ordersRepo.saveOrder(captureAny())).captured.single
            as Order;
    final expected = (item.price + newType.price) * order.quantity;

    expect(captured.amount, expected);
    expect(captured.type, newType);
  });

  test(
    'updating type should not update orders if there are no orders',
    () async {
      final typeRepo = MockTypeRepository();
      final ordersRepo = MockOrderRepository();

      when(typeRepo.watchTypes).thenAnswer(
        (_) => Stream.value([Type1(id: 'ty1', type: 'Extra', price: 100)]),
      );
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

    when(typeRepo.watchTypes).thenAnswer(
      (_) => Stream.value([Type1(id: 't1', type: 'Extra', price: 10)]),
    );
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

  test('deleteType delegates to repository', () async {
    final type = Type1(id: 't1', type: 'Extra', price: 20);

    final typeRepo = MockTypeRepository();
    final ordersRepo = MockOrderRepository();

    when(() => typeRepo.deleteType(any())).thenAnswer((_) async {});

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.deleteType(type);

    verify(() => typeRepo.deleteType(type)).called(1);
  });
}
