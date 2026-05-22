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

    final result =
        await dataSource.getOrdersBy(
              fields: ['table.tableNo'],
              values: [1],
              isEqualTo: [true],
            )
            as Map?;
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

      final result =
          await dataSource.getOrdersBy(
                fields: ['table.tableNo', 'status'],
                values: [5, 'pending'],
                isEqualTo: [true, true],
              )
              as Map?;
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

    final result =
        await dataSource.getOrdersBy(
              fields: ['table.tableNo'],
              values: [1],
              isEqualTo: [true],
              limitToOne: true,
            )
            as Map?;

    expect(result, isNotNull);
    expect(result!.length, 1);
    expect(result.containsKey(id1) || result.containsKey(id2), isTrue);
  });

  test('split orders are saved and queried separately', () async {
    final id = await dataSource.generateId(isSplit: true);
    await dataSource.save(id, sampleOrder(7), isSplit: true);

    final result =
        await dataSource.getOrdersBy(
              fields: ['table.tableNo'],
              values: [7],
              isEqualTo: [true],
              isSplit: true,
            )
            as Map?;

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

    final result =
        await dataSource.getOrdersBy(
              fields: ['status'],
              values: ['canceled'],
              isEqualTo: [false],
            )
            as Map?;

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

  test('watchOrders limits results to one when limitToOne is true', () async {
    final id1 = await dataSource.generateId(isSplit: false);
    await dataSource.save(id1, sampleOrder(15), isSplit: false);

    final id2 = await dataSource.generateId(isSplit: false);
    await dataSource.save(id2, sampleOrder(15), isSplit: false);

    final stream = dataSource.watchOrders(
      fields: ['table.tableNo'],
      values: [15],
      isEqualTo: [true],
      limitToOne: true,
    );

    final emitted =
        await stream.firstWhere((raw) => raw != null && (raw as Map).isNotEmpty)
            as Map?;

    expect(emitted, isNotNull);
    expect(emitted!.length, 1);
    expect(emitted.containsKey(id1) || emitted.containsKey(id2), isTrue);
  });

  group('updateAllTableNo', () {
    test('does nothing when list of ids is empty', () async {
      await expectLater(dataSource.updateAllTableNo([], 10), completes);
    });

    test('updates tableNo for multiple orders', () async {
      final id1 = await dataSource.generateId(isSplit: false);
      final id2 = await dataSource.generateId(isSplit: false);

      await dataSource.save(id1, sampleOrder(1), isSplit: false);
      await dataSource.save(id2, sampleOrder(1), isSplit: false);

      await dataSource.updateAllTableNo([id1, id2], 5);

      final doc1 = await orderRef.doc(id1).get();
      final doc2 = await orderRef.doc(id2).get();

      expect(doc1.data()?['table']?['tableNo'], 5);
      expect(doc2.data()?['table']?['tableNo'], 5);
    });

    test(
      'chunks and updates orders when list is larger than batch size (450)',
      () async {
        final ids = <String>[];
        final batch = orderRef.firestore.batch();
        for (int i = 0; i < 452; i++) {
          final docRef = orderRef.doc();
          ids.add(docRef.id);
          batch.set(docRef, sampleOrder(1));
        }
        await batch.commit();

        await dataSource.updateAllTableNo(ids, 8);

        final docFirst = await orderRef.doc(ids.first).get();
        final docLast = await orderRef.doc(ids.last).get();
        final docMiddle = await orderRef.doc(ids[449]).get();
        final docNext = await orderRef.doc(ids[450]).get();

        expect(docFirst.data()?['table']?['tableNo'], 8);
        expect(docLast.data()?['table']?['tableNo'], 8);
        expect(docMiddle.data()?['table']?['tableNo'], 8);
        expect(docNext.data()?['table']?['tableNo'], 8);
      },
    );
  });

  group('saveAll', () {
    test('does nothing when map is empty', () async {
      await expectLater(dataSource.saveAll({}, isSplit: false), completes);
    });

    test('saves multiple orders to correct collection (non-split)', () async {
      final id1 = await dataSource.generateId(isSplit: false);
      final id2 = await dataSource.generateId(isSplit: false);

      final data = {id1: sampleOrder(2), id2: sampleOrder(3)};

      await dataSource.saveAll(data, isSplit: false);

      final doc1 = await orderRef.doc(id1).get();
      final doc2 = await orderRef.doc(id2).get();

      expect(doc1.exists, true);
      expect(doc2.exists, true);
      expect(doc1.data()?['table']?['tableNo'], 2);
      expect(doc2.data()?['table']?['tableNo'], 3);
    });

    test('saves multiple orders to correct collection (split)', () async {
      final id1 = await dataSource.generateId(isSplit: true);
      final id2 = await dataSource.generateId(isSplit: true);

      final data = {id1: sampleOrder(4), id2: sampleOrder(5)};

      await dataSource.saveAll(data, isSplit: true);

      final doc1 = await splitOrderRef.doc(id1).get();
      final doc2 = await splitOrderRef.doc(id2).get();

      expect(doc1.exists, true);
      expect(doc2.exists, true);
      expect(doc1.data()?['table']?['tableNo'], 4);
      expect(doc2.data()?['table']?['tableNo'], 5);
    });

    test(
      'chunks and saves orders when map is larger than batch size (450)',
      () async {
        final data = <String, Map<String, dynamic>>{};
        final ids = <String>[];
        for (int i = 0; i < 452; i++) {
          final id = orderRef.doc().id;
          ids.add(id);
          data[id] = sampleOrder(i);
        }

        await dataSource.saveAll(data, isSplit: false);

        final docFirst = await orderRef.doc(ids.first).get();
        final docLast = await orderRef.doc(ids.last).get();
        final docNext = await orderRef.doc(ids[450]).get();

        expect(docFirst.exists, true);
        expect(docLast.exists, true);
        expect(docNext.exists, true);

        expect(docFirst.data()?['table']?['tableNo'], 0);
        expect(docLast.data()?['table']?['tableNo'], 451);
        expect(docNext.data()?['table']?['tableNo'], 450);
      },
    );
  });

  group('deleteAll', () {
    test('does nothing when list of ids is empty', () async {
      await expectLater(dataSource.deleteAll([], isSplit: false), completes);
    });

    test(
      'deletes multiple orders from correct collection (non-split)',
      () async {
        final id1 = await dataSource.generateId(isSplit: false);
        final id2 = await dataSource.generateId(isSplit: false);

        await dataSource.save(id1, sampleOrder(1), isSplit: false);
        await dataSource.save(id2, sampleOrder(1), isSplit: false);

        final doc1Before = await orderRef.doc(id1).get();
        final doc2Before = await orderRef.doc(id2).get();

        expect(doc1Before.exists, true);
        expect(doc2Before.exists, true);

        await dataSource.deleteAll([id1, id2], isSplit: false);

        final doc1 = await orderRef.doc(id1).get();
        final doc2 = await orderRef.doc(id2).get();

        expect(doc1.exists, false);
        expect(doc2.exists, false);
      },
    );

    test('deletes multiple orders from correct collection (split)', () async {
      final id1 = await dataSource.generateId(isSplit: true);
      final id2 = await dataSource.generateId(isSplit: true);

      await dataSource.save(id1, sampleOrder(1), isSplit: true);
      await dataSource.save(id2, sampleOrder(1), isSplit: true);

      final doc1Before = await splitOrderRef.doc(id1).get();
      final doc2Before = await splitOrderRef.doc(id2).get();

      expect(doc1Before.exists, true);
      expect(doc2Before.exists, true);

      await dataSource.deleteAll([id1, id2], isSplit: true);

      final doc1 = await splitOrderRef.doc(id1).get();
      final doc2 = await splitOrderRef.doc(id2).get();

      expect(doc1.exists, false);
      expect(doc2.exists, false);
    });

    test(
      'chunks and deletes orders when list is larger than batch size (450)',
      () async {
        final ids = <String>[];
        final batch = orderRef.firestore.batch();
        for (int i = 0; i < 452; i++) {
          final docRef = orderRef.doc();
          ids.add(docRef.id);
          batch.set(docRef, sampleOrder(1));
        }
        await batch.commit();

        final docFirstBefore = await orderRef.doc(ids.first).get();
        expect(docFirstBefore.exists, true);

        await dataSource.deleteAll(ids, isSplit: false);

        final docFirstAfter = await orderRef.doc(ids.first).get();
        final docLastAfter = await orderRef.doc(ids.last).get();
        final docNextAfter = await orderRef.doc(ids[450]).get();

        expect(docFirstAfter.exists, false);
        expect(docLastAfter.exists, false);
        expect(docNextAfter.exists, false);
      },
    );
  });
}
