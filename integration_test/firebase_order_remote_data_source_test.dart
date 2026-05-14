import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_order_remote_data_source.dart';
import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String businessId;
  late CollectionReference<Map<String, dynamic>> orderRef;
  late CollectionReference<Map<String, dynamic>> splitOrderRef;
  late FirebaseOrderRemoteDataSource dataSource;

  setUpAll(() async {
    await TestHelper.setupFirebase();
    businessId = 'order_test_${DateTime.now().millisecondsSinceEpoch}';
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await TestHelper.createBusiness(businessId, uid);

    final firestore = FirebaseFirestore.instance;
    orderRef = firestore.collection('orders');
    splitOrderRef = firestore.collection('split-orders');

    dataSource = FirebaseOrderRemoteDataSource(
      orderRef,
      splitOrderRef,
      businessId: businessId,
    );
  });

  tearDown(() async {
    Future<void> clearCollection(
      CollectionReference<Map<String, dynamic>> collection,
    ) async {
      final snapshot = await collection
          .where('businessId', isEqualTo: businessId)
          .get();
      if (snapshot.docs.isEmpty) {
        return;
      }
      final batch = collection.firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await clearCollection(orderRef);
    await clearCollection(splitOrderRef);
  });

  Map<String, dynamic> sampleOrder(int tableNo) => {
    'businessId': businessId,
    'item': {'name': 'Pizza'},
    'type': {'type': 'Food'},
    'table': {'tableNo': tableNo},
  };

  test('generateId generates id in correct reference', () async {
    final id = await dataSource.generateId(isSplit: false);
    expect(id, isNotEmpty);

    final splitId = await dataSource.generateId(isSplit: true);
    expect(splitId, isNotEmpty);
  });

  test('generateId uses correct reference for split and non-split', () async {
    final orderId = await dataSource.generateId(isSplit: false);

    await dataSource.save(orderId, {
      'businessId': businessId,
      'item': {'name': 'Pizza'},
      'type': {'type': 'Food'},
      'table': {'tableNo': 1},
    }, isSplit: false);

    final orderSnapshot = await orderRef.doc(orderId).get();
    final splitSnapshotForOrder = await splitOrderRef.doc(orderId).get();

    expect(orderSnapshot.exists, true);
    expect(splitSnapshotForOrder.exists, false);

    final splitId = await dataSource.generateId(isSplit: true);

    await dataSource.save(splitId, {
      'businessId': businessId,
      'item': {'name': 'Burger'},
      'type': {'type': 'Food'},
      'table': {'tableNo': 2},
    }, isSplit: true);

    final splitSnapshot = await splitOrderRef.doc(splitId).get();
    final orderSnapshotForSplit = await orderRef.doc(splitId).get();

    expect(splitSnapshot.exists, true);
    expect(orderSnapshotForSplit.exists, false);
  });

  test('save and getAllOrders returns data', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(1), isSplit: false);

    final result = await dataSource.getAllOrders() as Map?;
    expect(result, isNotNull);
    expect(result![id]['table']['tableNo'], 1);
  });

  test('queryOrdersByTable returns correct orders', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(5), isSplit: false);

    final result = await dataSource.queryOrdersByTable(5) as Map?;
    expect(result, isNotNull);
    expect(result!.values.first['table']['tableNo'], 5);
  });

  test('queryOrdersByTable returns null when no orders exist', () async {
    final result = await dataSource.queryOrdersByTable(1);

    expect(result, isNull);
  });

  test('queryOrdersByType returns correct orders', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(2), isSplit: false);

    final result = await dataSource.queryOrdersByType('Food') as Map?;
    expect(result, isNotNull);
    expect(result!.values.first['type']['type'], 'Food');
  });

  test('queryOrdersByType returns null when no orders exist', () async {
    final result = await dataSource.queryOrdersByType('Dine In');

    expect(result, isNull);
  });

  test('queryOrdersByItem returns correct orders', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(3), isSplit: false);

    final result = await dataSource.queryOrdersByItem('Pizza') as Map?;
    expect(result, isNotNull);
    expect(result!.values.first['item']['name'], 'Pizza');
  });

  test('queryOrdersByItem returns null when no orders exist', () async {
    final result = await dataSource.queryOrdersByItem('Pizza');

    expect(result, isNull);
  });

  test('updateTableNo updates nested field only', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(1), isSplit: false);

    await dataSource.updateTableNo(id, 10);

    final snapshot = await orderRef.doc(id).get();
    final data = snapshot.data()!;

    expect(data['table']['tableNo'], 10);
    expect(data['item']['name'], 'Pizza');
  });

  test('split orders are saved and queried separately', () async {
    final id = await dataSource.generateId(isSplit: true);
    await dataSource.save(id, sampleOrder(7), isSplit: true);

    final result = await dataSource.getSplitOrdersByTable(7) as Map?;

    expect(result, isNotNull);
    expect(result!.values.first['table']['tableNo'], 7);
  });

  test('watchOrders emits data', () async {
    final stream = dataSource.watchOrders();
    final id = await dataSource.generateId(isSplit: false);

    await dataSource.save(id, sampleOrder(4), isSplit: false);

    final emitted = await stream.firstWhere((raw) => raw != null) as Map?;
    expect(emitted, isNotNull);
  });

  test('delete removes order from correct ref', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(9), isSplit: false);

    await dataSource.delete(id, isSplit: false);

    final snapshot = await orderRef.doc(id).get();
    expect(snapshot.exists, false);
  });

  test('watchSplitOrders emits data when split order changes', () async {
    final stream = dataSource.watchSplitOrders();

    final id = await dataSource.generateId(isSplit: true);

    await dataSource.save(id, {
      'businessId': businessId,
      'item': {'name': 'Burger'},
      'type': {'type': 'Food'},
      'table': {'tableNo': 12},
    }, isSplit: true);

    final emitted = await stream.firstWhere((raw) => raw != null) as Map?;

    expect(emitted, isNotNull);
    expect(emitted![id]['table']['tableNo'], 12);
  });

  test('watchSplitOrders emits null after delete', () async {
    final id = await dataSource.generateId(isSplit: true);

    await dataSource.save(id, {
      'businessId': businessId,
      'item': {'name': 'Juice'},
      'type': {'type': 'Drink'},
      'table': {'tableNo': 2},
    }, isSplit: true);

    final stream = dataSource.watchSplitOrders();

    await dataSource.delete(id, isSplit: true);

    final emitted = await stream.firstWhere((raw) => raw == null);
    expect(emitted, isNull);
  });

  test(
    'getSplitOrdersByTable returns null when no split orders exist',
    () async {
      final result = await dataSource.getSplitOrdersByTable(1);

      expect(result, isNull);
    },
  );
}
