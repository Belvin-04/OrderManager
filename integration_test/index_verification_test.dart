import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late String businessId;
  late String userId;
  late String email;
  late String name;
  late String typeName;
  late String ownerId;

  setUpAll(() async {
    await TestHelper.setupFirebase();
    firestore = FirebaseFirestore.instance;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    businessId = 'index_test_biz_${DateTime.now().millisecondsSinceEpoch}';
    userId = uid;
    email = 'index_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    name = 'index_test_item_name';
    typeName = 'index_test_type_name';
    ownerId = uid;

    await TestHelper.createBusiness(businessId, uid);
  });

  Future<void> verifyQuery(String name, Query query) async {
    try {
      await query.get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' ||
          e.message?.contains('index') == true) {
        fail('Index required for query: $name. Link: ${e.message}');
      } else {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  group('FirebaseAppUserRemoteDataSource Query Indexes', () {
    test('watchEmployedBusinesses', () async {
      final query = firestore
          .collection('business_employees')
          .where('employeeId', isEqualTo: userId);
      await verifyQuery(
        'business_employees.where(employeeId == userId)',
        query,
      );
    });

    test('watchBusinessEmployees', () async {
      final query = firestore
          .collection('business_employees')
          .where('businessId', isEqualTo: businessId);
      await verifyQuery(
        'business_employees.where(businessId == businessId)',
        query,
      );
    });

    test('queryByEmail', () async {
      final query = firestore
          .collection('app_users')
          .where('email', isEqualTo: email);
      await verifyQuery('app_users.where(email == email)', query);
    });
  });

  group('FirebaseBusinessRemoteDataSource Query Indexes', () {
    test('watchBusiness', () async {
      final query = firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: ownerId);
      await verifyQuery('businesses.where(ownerId == ownerId)', query);
    });

    test('deleteBusinessCollections', () async {
      const collections = [
        'items',
        'types',
        'tables',
        'orders',
        'split-orders',
        'business_employees',
      ];
      for (final collection in collections) {
        final query = firestore
            .collection(collection)
            .where('businessId', isEqualTo: businessId);
        await verifyQuery('$collection.where(businessId == businessId)', query);
      }
    });
  });

  group('FirebaseItemRemoteDataSource Query Indexes', () {
    test('watchItems', () async {
      final query = firestore
          .collection('items')
          .where('businessId', isEqualTo: businessId);
      await verifyQuery('items.where(businessId == businessId)', query);
    });

    test('queryByName', () async {
      final query = firestore
          .collection('items')
          .where('businessId', isEqualTo: businessId)
          .where('name', isEqualTo: name);
      await verifyQuery(
        'items.where(businessId == businessId).where(name == name)',
        query,
      );
    });

    test('hasItems', () async {
      final query = firestore
          .collection('items')
          .where('businessId', isEqualTo: businessId)
          .limit(1);
      await verifyQuery(
        'items.where(businessId == businessId).limit(1)',
        query,
      );
    });
  });

  group('FirebaseTableRemoteDataSource Query Indexes', () {
    test('watchTables', () async {
      final query = firestore
          .collection('tables')
          .where('businessId', isEqualTo: businessId);
      await verifyQuery('tables.where(businessId == businessId)', query);
    });

    test('getLastTable', () async {
      final query = firestore
          .collection('tables')
          .where('businessId', isEqualTo: businessId)
          .where('tableNo', isGreaterThanOrEqualTo: 0)
          .orderBy('tableNo', descending: true)
          .limit(1);
      await verifyQuery(
        '''tables.where(businessId == businessId).where(tableNo >= 0).orderBy(tableNo DESC).limit(1)''',
        query,
      );
    });
  });

  group('FirebaseTypeRemoteDataSource Query Indexes', () {
    test('watchTypes', () async {
      final query = firestore
          .collection('types')
          .where('businessId', isEqualTo: businessId);
      await verifyQuery('types.where(businessId == businessId)', query);
    });

    test('queryByType', () async {
      final query = firestore
          .collection('types')
          .where('businessId', isEqualTo: businessId)
          .where('type', isEqualTo: typeName);
      await verifyQuery(
        'types.where(businessId == businessId).where(type == type)',
        query,
      );
    });

    test('hasTypes', () async {
      final query = firestore
          .collection('types')
          .where('businessId', isEqualTo: businessId)
          .limit(1);
      await verifyQuery(
        'types.where(businessId == businessId).limit(1)',
        query,
      );
    });
  });

  group('FirebaseOrderRemoteDataSource Query Indexes', () {
    const collections = ['orders', 'split-orders'];

    for (final collection in collections) {
      test('$collection: single field equality (table.tableNo)', () async {
        final query = firestore
            .collection(collection)
            .where('businessId', isEqualTo: businessId)
            .where('table.tableNo', isEqualTo: 1);
        await verifyQuery(
          '''$collection.where(businessId == businessId).where(table.tableNo == 1)''',
          query,
        );
      });

      test(
        '$collection: multiple field equality (table.tableNo and status)',
        () async {
          final query = firestore
              .collection(collection)
              .where('businessId', isEqualTo: businessId)
              .where('table.tableNo', isEqualTo: 5)
              .where('status', isEqualTo: 'pending');
          await verifyQuery(
            '''$collection.where(businessId == businessId).where(table.tableNo == 5).where(status == pending)''',
            query,
          );
        },
        skip: collection == 'split-orders',
      );

      test(
        '''$collection: single field inequality (status != canceled)''',
        () async {
          final query = firestore
              .collection(collection)
              .where('businessId', isEqualTo: businessId)
              .where('status', isNotEqualTo: 'canceled');
          await verifyQuery(
            '''$collection.where(businessId == businessId).where(status != canceled)''',
            query,
          );
        },
        skip: true,
      );

      test(
        '''$collection: multiple field equality and inequality (table.tableNo and status != canceled)''',
        () async {
          final query = firestore
              .collection(collection)
              .where('businessId', isEqualTo: businessId)
              .where('table.tableNo', isEqualTo: 1)
              .where('status', isNotEqualTo: 'canceled');
          await verifyQuery(
            '''$collection.where(businessId == businessId).where(table.tableNo == 1).where(status != canceled)''',
            query,
          );
        },
        skip: collection == 'split-orders',
      );
    }

    test(
      'split-orders: multiple field equality (table.tableNo and table.splitNo)',
      () async {
        final query = firestore
            .collection('split-orders')
            .where('businessId', isEqualTo: businessId)
            .where('table.tableNo', isEqualTo: 1)
            .where('table.splitNo', isEqualTo: 2);
        await verifyQuery(
          '''split-orders.where(businessId == businessId).where(table.tableNo == 1).where(table.splitNo == 2)''',
          query,
        );
      },
    );

    test(
      '''split-orders: multiple field equality and inequality (table.tableNo, table.splitNo and status != canceled)''',
      () async {
        final query = firestore
            .collection('split-orders')
            .where('businessId', isEqualTo: businessId)
            .where('table.tableNo', isEqualTo: 1)
            .where('table.splitNo', isEqualTo: 2)
            .where('status', isNotEqualTo: 'canceled');
        await verifyQuery(
          '''split-orders.where(businessId == businessId).where(table.tableNo == 1).where(table.splitNo == 2).where(status != canceled)''',
          query,
        );
      },
    );

    test('orders: nested field equality (type.type)', () async {
      final query = firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('type.type', isEqualTo: typeName);
      await verifyQuery(
        'orders.where(businessId == businessId).where(type.type == type)',
        query,
      );
    });

    test('orders: nested field equality (item.name)', () async {
      final query = firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('item.name', isEqualTo: name);
      await verifyQuery(
        'orders.where(businessId == businessId).where(item.name == name)',
        query,
      );
    });
  });
}
