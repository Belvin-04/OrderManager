import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/firebase_options.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_order_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseReference orderRef;
  late DatabaseReference splitOrderRef;
  late FirebaseOrderRemoteDataSource dataSource;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final db = FirebaseDatabase.instance;
    db.useDatabaseEmulator('localhost', 9000);

    orderRef = db.ref('orders_test');
    splitOrderRef = db.ref('split_orders_test');

    dataSource = FirebaseOrderRemoteDataSource(orderRef, splitOrderRef);
  });

  tearDown(() async {
    await orderRef.remove();
    await splitOrderRef.remove();
  });

  Map<String, dynamic> sampleOrder(int tableNo) => {
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
      'item': {'name': 'Pizza'},
      'type': {'type': 'Food'},
      'table': {'tableNo': 1},
    }, isSplit: false);

    final orderSnapshot = await orderRef.child(orderId).get();
    final splitSnapshotForOrder = await splitOrderRef.child(orderId).get();

    expect(orderSnapshot.exists, true);
    expect(splitSnapshotForOrder.exists, false);

    final splitId = await dataSource.generateId(isSplit: true);

    await dataSource.save(splitId, {
      'item': {'name': 'Burger'},
      'type': {'type': 'Food'},
      'table': {'tableNo': 2},
    }, isSplit: true);

    final splitSnapshot = await splitOrderRef.child(splitId).get();
    final orderSnapshotForSplit = await orderRef.child(splitId).get();

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

  test('queryOrdersByType returns correct orders', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(2), isSplit: false);

    final result = await dataSource.queryOrdersByType('Food') as Map?;
    expect(result, isNotNull);
    expect(result!.values.first['type']['type'], 'Food');
  });

  test('queryOrdersByItem returns correct orders', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(3), isSplit: false);

    final result = await dataSource.queryOrdersByItem('Pizza') as Map?;
    expect(result, isNotNull);
    expect(result!.values.first['item']['name'], 'Pizza');
  });

  test('updateTableNo updates nested field only', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(1), isSplit: false);

    await dataSource.updateTableNo(id, 10);

    final snapshot = await orderRef.child(id).get();
    final data = snapshot.value as Map;

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

    final emitted = await stream.first as Map?;
    expect(emitted, isNotNull);
  });

  test('delete removes order from correct ref', () async {
    final id = await dataSource.generateId(isSplit: false);
    await dataSource.save(id, sampleOrder(9), isSplit: false);

    await dataSource.delete(id, isSplit: false);

    final snapshot = await orderRef.child(id).get();
    expect(snapshot.exists, false);
  });

  test('watchSplitOrders emits data when split order changes', () async {
    final stream = dataSource.watchSplitOrders();

    final id = await dataSource.generateId(isSplit: true);

    await dataSource.save(id, {
      'item': {'name': 'Burger'},
      'type': {'type': 'Food'},
      'table': {'tableNo': 12},
    }, isSplit: true);

    final emitted = await stream.first as Map?;

    expect(emitted, isNotNull);
    expect(emitted![id]['table']['tableNo'], 12);
  });

  test('watchSplitOrders emits null after delete', () async {
    final id = await dataSource.generateId(isSplit: true);

    await dataSource.save(id, {
      'item': {'name': 'Juice'},
      'type': {'type': 'Drink'},
      'table': {'tableNo': 2},
    }, isSplit: true);

    final stream = dataSource.watchSplitOrders();

    await dataSource.delete(id, isSplit: true);

    final emitted = await stream.first;
    expect(emitted, isNull);
  });
}
