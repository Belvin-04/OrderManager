import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_item_remote_data_source.dart';
import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String businessId;
  late CollectionReference<Map<String, dynamic>> ref;
  late FirebaseItemRemoteDataSource dataSource;

  setUpAll(() async {
    await TestHelper.setupFirebase();
    businessId = 'item_test_${DateTime.now().millisecondsSinceEpoch}';
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await TestHelper.createBusiness(businessId, uid);

    final firestore = FirebaseFirestore.instance;
    ref = firestore.collection('items');
    dataSource = FirebaseItemRemoteDataSource(ref, businessId: businessId);
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

  test('save and queryByName returns correct item', () async {
    final id = await dataSource.generateId();

    final item = {'businessId': businessId, 'name': 'Laptop', 'price': 1200};

    await dataSource.save(id, item);

    final result = await dataSource.queryByName('Laptop') as Map?;

    expect(result, isNotNull);
    expect(result!.values.first['price'], 1200);
  });

  test('queryByName returns null when no match', () async {
    final result = await dataSource.queryByName('DoesNotExist');
    expect(result, isNull);
  });

  test('save and queryById returns correct item', () async {
    final id = await dataSource.generateId();

    final item = {
      'businessId': businessId,
      'id': id,
      'name': 'Laptop',
      'price': 1200,
    };

    await dataSource.save(id, item);

    final result = await dataSource.queryByName('Laptop') as Map?;
    final idResult =
        await dataSource.queryById(result!.values.first["id"]) as Map?;

    expect(idResult, isNotNull);
    expect(idResult!.values.first['price'], 1200);
  });

  test('queryById returns null when no match', () async {
    final result = await dataSource.queryById('DoesNotExist');
    expect(result, isNull);
  });

  test('delete removes item from database', () async {
    final id = await dataSource.generateId();

    await dataSource.save(id, {
      'businessId': businessId,
      'name': 'Phone',
      'price': 500,
    });

    await dataSource.delete(id);

    final snapshot = await ref.doc(id).get();
    expect(snapshot.exists, false);
  });

  test('watchItems emits when item is added', () async {
    final id = await dataSource.generateId();

    final stream = dataSource.watchItems();

    await dataSource.save(id, {
      'businessId': businessId,
      'name': 'Tablet',
      'price': 800,
    });

    final emitted = await stream.first as Map?;

    expect(emitted, isNotNull);
    expect(emitted![id]['name'], 'Tablet');
  });

  test(
    'hasItems returns true when items exist and false when they do not',
    () async {
      final initialResult = await dataSource.hasItems();
      expect(initialResult, false);

      final id = await dataSource.generateId();
      await dataSource.save(id, {
        'businessId': businessId,
        'name': 'Tablet',
        'price': 800,
      });

      final afterSaveResult = await dataSource.hasItems();
      expect(afterSaveResult, true);
    },
  );
}
