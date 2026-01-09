import 'dart:ui';

import 'package:order_manager/viewmodels/tables_viewmodel.dart';

class FakeTablesViewModel extends TablesViewmodel {
  RemoveTableResult removeResult = RemoveTableResult.noTables;
  ClearTableResult? clearTableResult;
  bool addCalled = false;
  SwapTableDecision? lastSwapDecision;
  String? clearedTableKey;
  String? confirmedClearKey;
  String? from;
  String? to;
  String? movedId;
  Offset? movedOffset;

  @override
  Future<void> addTable() async {
    addCalled = true;
  }

  @override
  Future<RemoveTableResult> removeTable() async {
    return removeResult;
  }

  @override
  Future<SwapTableDecision> swapTable(String tableKey) async {
    return lastSwapDecision!;
  }

  @override
  Future<ClearTableResult> clearTable(String tableKey) async {
    return clearTableResult!;
  }

  @override
  Future<void> clearTableConfirm(String tableKey) async {
    confirmedClearKey = tableKey;
  }

  @override
  Future<void> confirmSwap({
    required String fromTableKey,
    required String toTableKey,
  }) async {
    from = fromTableKey;
    to = toTableKey;
  }

  @override
  Future<void> updateTablePosition(String id, Offset offset) async {
    movedId = id;
    movedOffset = offset;
  }
}
