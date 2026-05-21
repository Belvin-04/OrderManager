import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_business_remote_data_source.dart';
import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseBusinessRemoteDataSource dataSource;
  late CollectionReference<Map<String, dynamic>> businessesRef;

  late String ownerId;
  late String businessId;

  setUpAll(() async {
    await TestHelper.setupFirebase();

    firestore = FirebaseFirestore.instance;
    ownerId = FirebaseAuth.instance.currentUser!.uid;

    businessesRef = firestore.collection('businesses');

    dataSource = FirebaseBusinessRemoteDataSource(
      businessesRef,
      ownerId: ownerId,
      firestore: firestore,
    );
  });

  setUp(() {
    businessId = 'business_${DateTime.now().millisecondsSinceEpoch}';
  });

  test('generateId returns non-empty id', () async {
    final id = await dataSource.generateId();

    expect(id, isNotEmpty);
  });

  test('save and queryById returns correct business', () async {
    final data = {'ownerId': ownerId, 'name': 'Business One'};

    await dataSource.save(businessId, data);

    final result = await dataSource.queryById(businessId) as Map?;

    expect(result, isNotNull);

    final business = result!.values.first;

    expect(business['name'], 'Business One');
    expect(business['ownerId'], ownerId);
  });

  test('queryById returns null for missing business', () async {
    final result = await dataSource.queryById('does_not_exist');

    expect(result, isNull);
  });

  test('watchBusiness emits saved businesses', () async {
    final stream = dataSource.watchBusiness();

    await dataSource.save(businessId, {
      'ownerId': ownerId,
      'name': 'Watched Business',
    });

    final emitted = await stream.first as Map?;

    expect(emitted, isNotNull);
    expect(emitted![businessId]['name'], 'Watched Business');
  });

  test('delete removes business', () async {
    await dataSource.save(businessId, {
      'ownerId': ownerId,
      'name': 'Delete Me',
    });

    await dataSource.delete(businessId);

    final snapshot = await businessesRef.doc(businessId).get();

    expect(snapshot.exists, false);
  });

  test('deleteBusinessCollections removes all related collections', () async {
    await dataSource.save(businessId, {
      'ownerId': ownerId,
      'name': 'Cascade Test',
    });

    final otherBusinessId = 'other_$businessId';
    await TestHelper.createBusiness(otherBusinessId, ownerId);

    const collections = [
      'items',
      'types',
      'tables',
      'orders',
      'split-orders',
      'business_employees',
    ];

    for (final collection in collections) {
      final data = {'businessId': businessId, 'value': 'test'};
      if (collection == 'business_employees') {
        data['employeeId'] = 'some_other_user';
        data['relationId'] = '${businessId}_some_other_user';
      }

      await firestore.collection(collection).add(data);

      final otherData = {
        'businessId': otherBusinessId,
        'value': 'should_remain',
      };
      if (collection == 'business_employees') {
        otherData['employeeId'] = 'another_user';
        otherData['relationId'] = '${otherBusinessId}_another_user';
      }

      await firestore.collection(collection).add(otherData);
    }

    await dataSource.deleteBusinessCollections(businessId);

    for (final collection in collections) {
      final deletedSnapshot = await firestore
          .collection(collection)
          .where('businessId', isEqualTo: businessId)
          .get();

      expect(deletedSnapshot.docs, isEmpty);

      final remainingSnapshot = await firestore
          .collection(collection)
          .where('businessId', isEqualTo: otherBusinessId)
          .get();

      expect(remainingSnapshot.docs.length, 1);
    }
  });
}
