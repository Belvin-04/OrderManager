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

  test('save and getOrdersBy returns data', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(1), isSplit: false);

    final result = await dataSource.getOrdersBy(
      fields: ['table.tableNo'],
      values: [1],
      isEqualTo: [true],
    ) as Map?;
    expect(result, isNotNull);
    expect(result![id]['table']['tableNo'], 1);
  });

  test(
    'getOrdersBy returns correct orders when querying multiple fields',
    () async {
      final id = await dataSource.generateId(isSplit: false);
      await dataSource.save(id, {
        ...sampleOrder(5),
        'status': 'pending',
      }, isSplit: false);

      final result = await dataSource.getOrdersBy(
        fields: ['table.tableNo', 'status'],
        values: [5, 'pending'],
        isEqualTo: [true, true],
      ) as Map?;
      expect(result, isNotNull);
      expect(result!.values.first['table']['tableNo'], 5);
      expect(result.values.first['status'], 'pending');
    },
  );

  test('getOrdersBy returns null when no matching orders exist', () async {
    final result = await dataSource.getOrdersBy(
      fields: ['table.tableNo'],
      values: [999],
      isEqualTo: [true],
    );

    expect(result, isNull);
  });

  test('getOrdersBy limits results to one when limitToOne is true', () async {
    final id1 = await dataSource.generateId(isSplit: false);
    await dataSource.save(id1, sampleOrder(1), isSplit: false);

    final id2 = await dataSource.generateId(isSplit: false);
    await dataSource.save(id2, sampleOrder(1), isSplit: false);

    final result = await dataSource.getOrdersBy(
      fields: ['table.tableNo'],
      values: [1],
      isEqualTo: [true],
      limitToOne: true,
    ) as Map?;

    expect(result, isNotNull);
    expect(result!.length, 1);
    expect(result.containsKey(id1) || result.containsKey(id2), isTrue);
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

    final result = await dataSource.getOrdersBy(
      fields: ['table.tableNo'],
      values: [7],
      isEqualTo: [true],
      isSplit: true,
    ) as Map?;

    expect(result, isNotNull);
    expect(result!.values.first['table']['tableNo'], 7);
  });

  test('getOrdersBy with isEqualTo false filters correctly', () async {
    final id1 = await dataSource.generateId(isSplit: false);
    await dataSource.save(id1, {
      'businessId': businessId,
      'status': 'canceled',
    }, isSplit: false);

    final id2 = await dataSource.generateId(isSplit: false);
    await dataSource.save(id2, {
      'businessId': businessId,
      'status': 'pending',
    }, isSplit: false);

    final result = await dataSource.getOrdersBy(
      fields: ['status'],
      values: ['canceled'],
      isEqualTo: [false],
    ) as Map?;

    expect(result, isNotNull);
    expect(result!.containsKey(id2), true);
    expect(result.containsKey(id1), false);
  });

  test('watchOrders emits data', () async {
    final stream = dataSource.watchOrders(
      fields: ['table.tableNo'],
      values: [4],
      isEqualTo: [true],
    );
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

  test('watchOrders emits data when split order changes', () async {
    final stream = dataSource.watchOrders(
      fields: ['table.tableNo'],
      values: [12],
      isEqualTo: [true],
      isSplit: true,
    );

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

  test('watchOrders with isEqualTo false filters correctly', () async {
    final id1 = await dataSource.generateId(isSplit: false);
    await dataSource.save(id1, {
      'businessId': businessId,
      'status': 'canceled',
    }, isSplit: false);

    final id2 = await dataSource.generateId(isSplit: false);
    await dataSource.save(id2, {
      'businessId': businessId,
      'status': 'pending',
    }, isSplit: false);

    final stream = dataSource.watchOrders(
      fields: ['status'],
      values: ['canceled'],
      isEqualTo: [false],
    );

    final emitted = await stream.firstWhere((raw) => raw != null) as Map?;
    expect(emitted, isNotNull);
    expect(emitted!.containsKey(id2), true);
    expect(emitted.containsKey(id1), false);
  });
}
