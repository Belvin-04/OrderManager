import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_table_remote_data_source.dart';
import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String businessId;
  late CollectionReference<Map<String, dynamic>> ref;
  late FirebaseTableRemoteDataSource dataSource;

  setUpAll(() async {
    await TestHelper.setupFirebase();
    businessId = 'table_test_${DateTime.now().millisecondsSinceEpoch}';
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await TestHelper.createBusiness(businessId, uid);

    final firestore = FirebaseFirestore.instance;
    ref = firestore.collection('tables');
    dataSource = FirebaseTableRemoteDataSource(ref, businessId: businessId);
  });

  tearDown(() async {
    final snapshot = await ref.where('businessId', isEqualTo: businessId).get();
    if (snapshot.docs.isEmpty) {
      return;
    }
    final batch = ref.firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  });

  test('generateId returns a non-empty id', () async {
    final id = await dataSource.generateId();
    expect(id, isNotEmpty);
  });

  test('save and watchTables emits data', () async {
    final id = await dataSource.generateId();

    final stream = dataSource.watchTables();

    await dataSource.save(id, {
      'businessId': businessId,
      'tableNo': 1,
      'capacity': 4,
    });

    final emitted = await stream.first as Map?;

    expect(emitted, isNotNull);
    expect(emitted![id]['capacity'], 4);
  });

  test('getLastTable returns table with highest tableNo', () async {
    await dataSource.save('t1', {
      'businessId': businessId,
      'tableNo': 1,
      'capacity': 2,
    });

    await dataSource.save('t2', {
      'businessId': businessId,
      'tableNo': 3,
      'capacity': 6,
    });

    await dataSource.save('t3', {
      'businessId': businessId,
      'tableNo': 2,
      'capacity': 4,
    });

    final result = await dataSource.getLastTable() as Map?;

    expect(result, isNotNull);

    final table = result!.values.first;
    expect(table['tableNo'], 3);
    expect(table['capacity'], 6);
  });

  test('updatePosition updates only position field', () async {
    final id = await dataSource.generateId();

    await dataSource.save(id, {
      'businessId': businessId,
      'tableNo': 5,
      'capacity': 4,
      'position': {'x': 0, 'y': 0},
    });

    await dataSource.updatePosition(id, {'x': 10, 'y': 20});

    final snapshot = await ref.doc(id).get();
    final data = snapshot.data()!;

    expect(data['tableNo'], 5);
    expect(data['capacity'], 4);
    expect(data['position']['x'], 10);
    expect(data['position']['y'], 20);
  });

  test('delete removes table from database', () async {
    final id = await dataSource.generateId();

    await dataSource.save(id, {
      'businessId': businessId,
      'tableNo': 9,
      'capacity': 8,
    });

    await dataSource.delete(id);

    final snapshot = await ref.doc(id).get();
    expect(snapshot.exists, false);
  });

  test(
    'getLastTable returns null when all tableNo values are invalid',
    () async {
      await dataSource.save('1', {
        'businessId': businessId,
        'tableNo': 'invalid',
      });

      await dataSource.save('2', {'businessId': businessId, 'tableNo': null});

      final result = await dataSource.getLastTable();

      expect(result, isNull);
    },
  );
}
