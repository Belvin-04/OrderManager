import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_type_remote_data_source.dart';
import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String businessId;
  late CollectionReference<Map<String, dynamic>> ref;
  late FirebaseTypeRemoteDataSource dataSource;

  setUpAll(() async {
    await TestHelper.setupFirebase();
    businessId = 'type_test_${DateTime.now().millisecondsSinceEpoch}';
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await TestHelper.createBusiness(businessId, uid);

    final firestore = FirebaseFirestore.instance;
    ref = firestore.collection('types');
    dataSource = FirebaseTypeRemoteDataSource(ref, businessId: businessId);
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

  test('save and queryById returns correct type', () async {
    final id = await dataSource.generateId();

    final typeData = {'businessId': businessId, 'id': id, 'type': 'Food'};

    await dataSource.save(id, typeData);

    final idResult = await dataSource.queryById(id) as Map?;

    expect(idResult, isNotNull);
    expect(idResult!.values.first['type'], 'Food');
  });

  test('queryById returns null when no match', () async {
    final result = await dataSource.queryById('DoesNotExist');
    expect(result, isNull);
  });

  test('delete removes type from database', () async {
    final id = await dataSource.generateId();

    await dataSource.save(id, {'businessId': businessId, 'type': 'Dessert'});

    await dataSource.delete(id);

    final snapshot = await ref.doc(id).get();
    expect(snapshot.exists, false);
  });

  test('watchTypes emits when type is added', () async {
    final id = await dataSource.generateId();

    final stream = dataSource.watchTypes();

    await dataSource.save(id, {'businessId': businessId, 'type': 'Appetizer'});

    final emitted = await stream.first as Map?;

    expect(emitted, isNotNull);
    expect(emitted![id]['type'], 'Appetizer');
  });

  test(
    'hasTypes returns true when types exist and false when they do not',
    () async {
      final initialResult = await dataSource.hasTypes();
      expect(initialResult, false);

      final id = await dataSource.generateId();
      await dataSource.save(id, {
        'businessId': businessId,
        'type': 'Drinks',
        'price': 10,
      });

      final afterSaveResult = await dataSource.hasTypes();
      expect(afterSaveResult, true);
    },
  );
}
