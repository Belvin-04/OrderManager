import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';

enum RemoveTableResult { noTables, hasOrders, removed }

enum ClearTableResult { hasPendingOrders, alreadyCleared, canClear }

enum SwapTableResult { canSwap, noFreeTables, noOrdersOnSource, noOrdersAtAll }

enum TableOrderStatus { pending, completed, canceled, empty }

class SwapTableDecision {
  final SwapTableResult result;
  final List<int> availableTables;

  SwapTableDecision({required this.result, this.availableTables = const []});
}

class TablesViewmodel extends AsyncNotifier<void> {
  late TableRepository _tableRepo;
  late OrderRepository _orderRepo;

  @override
  FutureOr<void> build() {
    _tableRepo = ref.read(tableRepositoryProvider);
    _orderRepo = ref.read(orderRepositoryProvider);
  }

  Future<void> addTable() async {
    _tableRepo = ref.read(tableRepositoryProvider);
    _orderRepo = ref.read(orderRepositoryProvider);
    final lastNo = await _tableRepo.getLastTable();
    final nextTableNo = (lastNo?.tableNo ?? 0) + 1;
    await _tableRepo.addTable(nextTableNo);
  }

  Future<RemoveTableResult> removeTable() async {
    _tableRepo = ref.read(tableRepositoryProvider);
    _orderRepo = ref.read(orderRepositoryProvider);
    final lastTable = await _tableRepo.getLastTable();

    if (lastTable == null) {
      return RemoveTableResult.noTables;
    }

    final hasOrders = await _orderRepo.hasAnyOrdersForTable(
      lastTable.tableNo.toString(),
    );
    if (hasOrders) {
      return RemoveTableResult.hasOrders;
    }

    await _tableRepo.deleteTableById(lastTable.id);
    return RemoveTableResult.removed;
  }

  Future<ClearTableResult> clearTable(String tableKey) async {
    _tableRepo = ref.read(tableRepositoryProvider);
    _orderRepo = ref.read(orderRepositoryProvider);
    final hasAnyOrders = await _orderRepo.hasAnyOrdersForTable(tableKey);

    if (!hasAnyOrders) {
      return ClearTableResult.alreadyCleared;
    }

    final hasPending = await _orderRepo.hasPendingOrdersForTable(tableKey);

    if (hasPending) {
      return ClearTableResult.hasPendingOrders;
    }
    return ClearTableResult.canClear;
  }

  Future<void> clearTableConfirm(String tableKey) async {
    _tableRepo = ref.read(tableRepositoryProvider);
    _orderRepo = ref.read(orderRepositoryProvider);
    await _orderRepo.deleteOrdersForTable(tableKey);
  }

  Future<SwapTableDecision> swapTable(String sourceTableKey) async {
    _tableRepo = ref.read(tableRepositoryProvider);
    _orderRepo = ref.read(orderRepositoryProvider);
    final tables = await _tableRepo.watchTables().first;
    Set<int> occupiedTables = await _orderRepo.getOccupiedTableNos();

    occupiedTables.remove(0);

    if (occupiedTables.isEmpty) {
      return SwapTableDecision(result: SwapTableResult.noOrdersAtAll);
    }

    final ordersOnSource = await _orderRepo.getOrdersForTable(sourceTableKey);

    if (ordersOnSource.isEmpty) {
      return SwapTableDecision(result: SwapTableResult.noOrdersOnSource);
    }

    final allTableNos = tables.map((t) => t.tableNo).toSet();
    final freeTables = allTableNos.difference(occupiedTables).toList();

    if (freeTables.isEmpty) {
      return SwapTableDecision(result: SwapTableResult.noFreeTables);
    }

    return SwapTableDecision(
      result: SwapTableResult.canSwap,
      availableTables: freeTables,
    );
  }

  Future<void> confirmSwap({
    required String fromTableKey,
    required String toTableKey,
  }) async {
    _tableRepo = ref.read(tableRepositoryProvider);
    _orderRepo = ref.read(orderRepositoryProvider);
    await _orderRepo.moveOrders(fromTableKey, toTableKey);
  }

  Future<void> updateTablePosition(String id, Offset newPos) async {
    _tableRepo = ref.read(tableRepositoryProvider);
    _orderRepo = ref.read(orderRepositoryProvider);
    await _tableRepo.updateTablePosition(id, newPos);
  }

  Stream<TableOrderStatus> getTableOrderStatus(String tableKey) {
    _tableRepo = ref.read(tableRepositoryProvider);
    _orderRepo = ref.read(orderRepositoryProvider);
    return _orderRepo.watchOrdersForTable(tableKey).map((orders) {
      if (orders.isNotEmpty) {
        final hasPending = orders.any((o) => o.status == "pending");
        if (hasPending) return TableOrderStatus.pending;

        final hasCompleted = orders.any((o) => o.status == "completed");
        if (hasCompleted) return TableOrderStatus.completed;

        final hasCanceled = orders.any((o) => o.status == "canceled");
        if (hasCanceled) return TableOrderStatus.canceled;
      }
      return TableOrderStatus.empty;
    });
  }
}
