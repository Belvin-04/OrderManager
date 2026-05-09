import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/firebase_options.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_app_user_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAppUserRemoteDataSource dataSource;
  late CollectionReference<Map<String, dynamic>> usersRef;

  late String userId;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    firestore = FirebaseFirestore.instance;

    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    firestore.useFirestoreEmulator('localhost', 8080);

    await FirebaseAuth.instance.signInAnonymously();
    await FirebaseAuth.instance.authStateChanges().first;

    usersRef = firestore.collection('app_users');
    dataSource = FirebaseAppUserRemoteDataSource(usersRef);
  });

  setUp(() {
    userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
  });

  tearDown(() async {
    final snapshot = await usersRef.get();
    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  });

  Map<String, dynamic> sampleUserData(String id) => {
    'id': id,
    'email': '$id@example.com',
    'name': 'User $id',
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
    final otherId = '${userId}_other';
    await dataSource.saveUser(userId, sampleUserData(userId));
    await dataSource.saveUser(otherId, sampleUserData(otherId));

    final result = await dataSource.queryByEmail('$userId@example.com') as Map?;

    expect(result, isNotNull);
    expect(result!.length, 1);
    expect(result.containsKey(userId), isTrue);
  });

  test(
    'watchBusinessUsers emits null when no users belong to business',
    () async {
      const businessId = 'biz_empty';

      final stream = dataSource.watchBusinessUsers(businessId);

      final emitted = await stream.first;

      expect(emitted, isNull);
    },
    skip: true,
  );

  test('watchBusinessUsers emits map of users belonging to business', () async {
    const businessId = 'biz_test';

    final data = {...sampleUserData(userId), 'businessId': businessId};
    await dataSource.saveUser(userId, data);

    final stream = dataSource.watchBusinessUsers(businessId);

    final emitted = await stream.firstWhere((e) => e != null) as Map?;

    expect(emitted, isNotNull);
    expect(emitted!.containsKey(userId), isTrue);
    expect(emitted[userId]['businessId'], businessId);
  }, skip: true);

  test(
    'watchBusinessUsers does not include users from other businesses',
    () async {
      const businessId = 'biz_a';
      const otherBusinessId = 'biz_b';

      final otherId = '${userId}_other';

      await dataSource.saveUser(userId, {
        ...sampleUserData(userId),
        'businessId': businessId,
      });

      await dataSource.saveUser(otherId, {
        ...sampleUserData(otherId),
        'businessId': otherBusinessId,
      });

      final stream = dataSource.watchBusinessUsers(businessId);
      final emitted = await stream.firstWhere((e) => e != null) as Map?;

      expect(emitted, isNotNull);
      expect(emitted!.length, 1);
      expect(emitted.containsKey(userId), isTrue);
      expect(emitted.containsKey(otherId), isFalse);
    },
    skip: true,
  );
}
