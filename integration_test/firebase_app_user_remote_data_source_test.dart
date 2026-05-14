import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_app_user_remote_data_source.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAppUserRemoteDataSource dataSource;
  late CollectionReference<Map<String, dynamic>> usersRef;
  late CollectionReference<Map<String, dynamic>> businessUsersRef;

  late String userId;

  setUpAll(() async {
    await TestHelper.setupFirebase();

    firestore = FirebaseFirestore.instance;
    usersRef = firestore.collection('app_users');
    businessUsersRef = firestore.collection('business_employees');
    dataSource = FirebaseAppUserRemoteDataSource(usersRef, businessUsersRef);
  });

  setUp(() async {
    userId = FirebaseAuth.instance.currentUser!.uid;
  });

  tearDown(() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await usersRef.doc(uid).delete();
        await businessUsersRef.doc('r_$uid').delete();
      } catch (_) {}
    }
  });

  Map<String, dynamic> sampleUserData(String id) => {
    'id': id,
    'email': '$id@example.com',
    'name': 'User $id',
  };

  Map<String, dynamic> sampleBusinessUserData(String id, String businessId) => {
    'relationId': 'r_$id',
    'businessId': businessId,
    'businessName': 'Business $businessId',
    'employeeId': 'e_$id',
    'employeeName': 'Employee $id',
    'employeeEmail': 'e_$id@example.com',
    'employeeRole': 'Role $id',
  };

  test('saveUser writes document to Firestore', () async {
    final data = sampleUserData(userId);

    await dataSource.saveUser(userId, data);

    final snapshot = await usersRef.doc(userId).get();

    expect(snapshot.exists, isTrue);
    expect(snapshot.data()!['email'], '$userId@example.com');
  });

  test('saveUser overwrites existing document', () async {
    await dataSource.saveUser(userId, sampleUserData(userId));
    await dataSource.saveUser(userId, {
      ...sampleUserData(userId),
      'name': 'Updated',
    });

    final snapshot = await usersRef.doc(userId).get();

    expect(snapshot.data()!['name'], 'Updated');
  });

  test('deleteUser removes document from Firestore', () async {
    await dataSource.saveUser(userId, sampleUserData(userId));

    await dataSource.deleteUser(userId);

    final snapshot = await usersRef.doc(userId).get();

    expect(snapshot.exists, isFalse);
  });

  test('queryById returns null for non-existent user', () async {
    final result = await dataSource.queryById('does_not_exist');

    expect(result, isNull);
  });

  test('queryById returns map keyed by id for existing user', () async {
    final data = sampleUserData(userId);

    await dataSource.saveUser(userId, data);

    final result = await dataSource.queryById(userId) as Map?;

    expect(result, isNotNull);
    expect(result!.containsKey(userId), isTrue);
    expect(result[userId]['email'], '$userId@example.com');
  });

  test('queryByEmail returns null when no user matches', () async {
    final result = await dataSource.queryByEmail('nobody@example.com');

    expect(result, isNull);
  });

  test('queryByEmail returns map for matching user', () async {
    final data = sampleUserData(userId);
    await dataSource.saveUser(userId, data);

    final result = await dataSource.queryByEmail('$userId@example.com') as Map?;

    expect(result, isNotNull);
    expect(result!.containsKey(userId), isTrue);
    expect(result[userId]['name'], 'User $userId');
  });

  test('queryByEmail ignores users with a different email', () async {
    final originalUid = FirebaseAuth.instance.currentUser!.uid;
    await dataSource.saveUser(originalUid, sampleUserData(originalUid));

    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
    final otherUid = FirebaseAuth.instance.currentUser!.uid;
    await dataSource.saveUser(otherUid, sampleUserData(otherUid));

    final result =
        await dataSource.queryByEmail('$originalUid@example.com') as Map?;

    expect(result, isNotNull);
    expect(result!.length, 1);
    expect(result.containsKey(originalUid), isTrue);
    expect(result.containsKey(otherUid), isFalse);
  });

  test(
    'watchBusinessEmployees emits null when no users belong to business',
    () async {
      final businessId = 'app_user_test_empty_$userId';
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await TestHelper.createBusiness(businessId, uid);

      final stream = dataSource.watchBusinessEmployees(businessId);

      final emitted = await stream.first;

      expect(emitted, isNull);
    },
  );

  test(
    'watchBusinessEmployees emits map of users belonging to business',
    () async {
      final businessId = 'app_user_test_map_$userId';
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await TestHelper.createBusiness(businessId, uid);

      final data = sampleBusinessUserData(userId, businessId);
      await dataSource.addBusinessEmployee(data['relationId'], data);

      final stream = dataSource.watchBusinessEmployees(businessId);

      final emitted = await stream.firstWhere((e) => e != null) as Map?;

      expect(emitted, isNotNull);
      expect(emitted!.containsKey(data['relationId']), isTrue);
      expect(emitted[data['relationId']]['businessId'], businessId);
    },
  );

  test(
    'watchBusinessEmployees does not include users from other businesses',
    () async {
      final businessId = 'app_user_test_a_$userId';
      final otherBusinessId = 'app_user_test_b_$userId';
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await TestHelper.createBusiness(businessId, uid);
      await TestHelper.createBusiness(otherBusinessId, uid);

      final otherId = '${userId}_other';

      final dataA = sampleBusinessUserData(userId, businessId);
      await dataSource.addBusinessEmployee(dataA['relationId'], dataA);

      final dataB = sampleBusinessUserData(otherId, otherBusinessId);
      await dataSource.addBusinessEmployee(dataB['relationId'], dataB);

      final stream = dataSource.watchBusinessEmployees(businessId);
      final emitted = await stream.firstWhere((e) => e != null) as Map?;

      expect(emitted, isNotNull);
      expect(emitted!.length, 1);
      expect(emitted.containsKey(dataA['relationId']), isTrue);
      expect(emitted.containsKey(dataB['relationId']), isFalse);
    },
  );

  test('addBusinessEmployee adds document to firestore', () async {
    final businessId = 'app_user_test_add_$userId';
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await TestHelper.createBusiness(businessId, uid);

    final data = sampleBusinessUserData(userId, businessId);
    var snapshot = await businessUsersRef.doc(data['relationId']).get();
    expect(snapshot.exists, isFalse);

    await dataSource.addBusinessEmployee(data['relationId'], data);
    snapshot = await businessUsersRef.doc(data['relationId']).get();
    expect(snapshot.exists, isTrue);
  });

  test('removeBusinessEmployee deletes document', () async {
    final businessId = 'app_user_test_remove_$userId';
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await TestHelper.createBusiness(businessId, uid);

    final data = sampleBusinessUserData(userId, businessId);
    await dataSource.addBusinessEmployee(data['relationId'], data);

    final beforeSnapshot = await businessUsersRef.doc(data['relationId']).get();
    expect(beforeSnapshot.exists, isTrue);

    await dataSource.removeBusinessEmployee(data['relationId']);

    final afterSnapshot = await businessUsersRef.doc(data['relationId']).get();
    expect(afterSnapshot.exists, isFalse);
  });
}
