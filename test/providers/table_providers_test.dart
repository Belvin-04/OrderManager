import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart'
    show TableOrderStatus;
import '../test_helper.dart';

void main() {
  late MockOrderRepository mockOrderRepo;

  setUp(() {
    mockOrderRepo = MockOrderRepository();
  });

  group('table_providers existence providers', () {
    test('pendingOrdersExistProvider emits pending status', () async {
      when(
        () => mockOrderRepo.watchPendingOrdersExist('t1'),
      ).thenAnswer((_) => Stream.value(true));

      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(mockOrderRepo)],
      );
      addTearDown(container.dispose);

      final completer = Completer<bool>();
      final sub = container.listen(pendingOrdersExistProvider('t1'), (_, next) {
        if (next is AsyncData<bool>) {
          completer.complete(next.value);
        }
      });

      expect(await completer.future, isTrue);
      sub.close();
    });

    test('completedOrdersExistProvider emits completed status', () async {
      when(
        () => mockOrderRepo.watchCompletedOrdersExist('t1'),
      ).thenAnswer((_) => Stream.value(false));

      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(mockOrderRepo)],
      );
      addTearDown(container.dispose);

      final completer = Completer<bool>();
      final sub = container.listen(completedOrdersExistProvider('t1'), (
        _,
        next,
      ) {
        if (next is AsyncData<bool>) {
          completer.complete(next.value);
        }
      });

      expect(await completer.future, isFalse);
      sub.close();
    });

    test('canceledOrdersExistProvider emits canceled status', () async {
      when(
        () => mockOrderRepo.watchCanceledOrdersExist('t1'),
      ).thenAnswer((_) => Stream.value(true));

      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(mockOrderRepo)],
      );
      addTearDown(container.dispose);

      final completer = Completer<bool>();
      final sub = container.listen(canceledOrdersExistProvider('t1'), (
        _,
        next,
      ) {
        if (next is AsyncData<bool>) {
          completer.complete(next.value);
        }
      });

      expect(await completer.future, isTrue);
      sub.close();
    });
  });

  group('tableOrderStatus provider', () {
    test('returns loading if any source provider is loading', () {
      final pendingController = StreamController<bool>();
      final completedController = StreamController<bool>();
      final canceledController = StreamController<bool>();

      when(
        () => mockOrderRepo.watchPendingOrdersExist('t1'),
      ).thenAnswer((_) => pendingController.stream);
      when(
        () => mockOrderRepo.watchCompletedOrdersExist('t1'),
      ).thenAnswer((_) => completedController.stream);
      when(
        () => mockOrderRepo.watchCanceledOrdersExist('t1'),
      ).thenAnswer((_) => canceledController.stream);

      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(mockOrderRepo)],
      );
      addTearDown(container.dispose);

      final status = container.read(tableOrderStatus('t1'));
      expect(status, isA<AsyncLoading<TableOrderStatus>>());

      pendingController.close();
      completedController.close();
      canceledController.close();
    });

    test(
      '''returns pending status when pending orders exist, regardless of other streams''',
      () async {
        when(
          () => mockOrderRepo.watchPendingOrdersExist('t1'),
        ).thenAnswer((_) => Stream.value(true));
        when(
          () => mockOrderRepo.watchCompletedOrdersExist('t1'),
        ).thenAnswer((_) => Stream.value(true));
        when(
          () => mockOrderRepo.watchCanceledOrdersExist('t1'),
        ).thenAnswer((_) => Stream.value(true));

        final container = ProviderContainer(
          overrides: [orderRepositoryProvider.overrideWithValue(mockOrderRepo)],
        );
        addTearDown(container.dispose);

        final completer = Completer<TableOrderStatus>();
        final sub = container.listen(tableOrderStatus('t1'), (_, next) {
          if (next is AsyncData<TableOrderStatus>) {
            completer.complete(next.value);
          }
        });

        expect(await completer.future, TableOrderStatus.pending);
        sub.close();
      },
    );

    test(
      '''returns completed status when completed orders exist and no pending orders exist''',
      () async {
        when(
          () => mockOrderRepo.watchPendingOrdersExist('t1'),
        ).thenAnswer((_) => Stream.value(false));
        when(
          () => mockOrderRepo.watchCompletedOrdersExist('t1'),
        ).thenAnswer((_) => Stream.value(true));
        when(
          () => mockOrderRepo.watchCanceledOrdersExist('t1'),
        ).thenAnswer((_) => Stream.value(true));

        final container = ProviderContainer(
          overrides: [orderRepositoryProvider.overrideWithValue(mockOrderRepo)],
        );
        addTearDown(container.dispose);

        final completer = Completer<TableOrderStatus>();
        final sub = container.listen(tableOrderStatus('t1'), (_, next) {
          if (next is AsyncData<TableOrderStatus>) {
            completer.complete(next.value);
          }
        });

        expect(await completer.future, TableOrderStatus.completed);
        sub.close();
      },
    );

    test(
      'returns canceled status when canceled orders exist, and no pending/completed orders exist',
      () async {
        when(
          () => mockOrderRepo.watchPendingOrdersExist('t1'),
        ).thenAnswer((_) => Stream.value(false));
        when(
          () => mockOrderRepo.watchCompletedOrdersExist('t1'),
        ).thenAnswer((_) => Stream.value(false));
        when(
          () => mockOrderRepo.watchCanceledOrdersExist('t1'),
        ).thenAnswer((_) => Stream.value(true));

        final container = ProviderContainer(
          overrides: [orderRepositoryProvider.overrideWithValue(mockOrderRepo)],
        );
        addTearDown(container.dispose);

        final completer = Completer<TableOrderStatus>();
        final sub = container.listen(tableOrderStatus('t1'), (_, next) {
          if (next is AsyncData<TableOrderStatus>) {
            completer.complete(next.value);
          }
        });

        expect(await completer.future, TableOrderStatus.canceled);
        sub.close();
      },
    );

    test('returns empty status when no orders exist', () async {
      when(
        () => mockOrderRepo.watchPendingOrdersExist('t1'),
      ).thenAnswer((_) => Stream.value(false));
      when(
        () => mockOrderRepo.watchCompletedOrdersExist('t1'),
      ).thenAnswer((_) => Stream.value(false));
      when(
        () => mockOrderRepo.watchCanceledOrdersExist('t1'),
      ).thenAnswer((_) => Stream.value(false));

      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(mockOrderRepo)],
      );
      addTearDown(container.dispose);

      final completer = Completer<TableOrderStatus>();
      final sub = container.listen(tableOrderStatus('t1'), (_, next) {
        if (next is AsyncData<TableOrderStatus>) {
          completer.complete(next.value);
        }
      });

      expect(await completer.future, TableOrderStatus.empty);
      sub.close();
    });
  });
}
