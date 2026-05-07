import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/firebase_options.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_type_remote_data_source.dart';

void main() {
  const businessId = 'business_type_test';
  late CollectionReference<Map<String, dynamic>> ref;
  late FirebaseTypeRemoteDataSource dataSource;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    firestore.useFirestoreEmulator('localhost', 8080);
    await FirebaseAuth.instance.signInAnonymously();

    await FirebaseAuth.instance.authStateChanges().first;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await firestore.collection('businesses').doc(businessId).set({
      'ownerId': uid,
    });

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

  test('generateId returns a valid id', () async {
    final id = await dataSource.generateId();
    expect(id, isNotEmpty);
  });

  test('save and queryByType returns correct data', () async {
    final id = await dataSource.generateId();

    final data = {'businessId': businessId, 'type': 'food', 'name': 'Pizza'};

    await dataSource.save(id, data);

    final result = await dataSource.queryByType('food') as Map?;

    expect(result, isNotNull);
    expect(result!.values.first['name'], 'Pizza');
  });

  test('queryByType returns null when no match', () async {
    final result = await dataSource.queryByType('DoesNotExist');
    expect(result, isNull);
  });

  test('save and queryById returns correct data', () async {
    final id = await dataSource.generateId();

    final data = {
      'businessId': businessId,
      'id': id,
      'type': 'food',
      'name': 'Pizza',
    };

    await dataSource.save(id, data);

    final result = await dataSource.queryByType('food') as Map?;

    final idResult =
        await dataSource.queryById(result!.values.first["id"]) as Map?;

    expect(idResult, isNotNull);
    expect(idResult!.values.first['name'], 'Pizza');
  });

  test('queryById returns null when no match', () async {
    final result = await dataSource.queryById('DoesNotExist');
    expect(result, isNull);
  });

  test('delete removes data from database', () async {
    final id = await dataSource.generateId();

    await dataSource.save(id, {
      'businessId': businessId,
      'type': 'drink',
      'name': 'Coffee',
    });

    await dataSource.delete(id);

    final snapshot = await ref.doc(id).get();
    expect(snapshot.exists, false);
  });

  test('watchTypes emits data changes', () async {
    final id = await dataSource.generateId();

    final stream = dataSource.watchTypes();

    await dataSource.save(id, {
      'businessId': businessId,
      'type': 'snack',
      'name': 'Burger',
    });

    final emitted = await stream.first as Map?;

    expect(emitted, isNotNull);
    expect(emitted![id]['name'], 'Burger');
  });
}
