import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/firebase_options.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_type_remote_data_source.dart';

void main() {
  late DatabaseReference ref;
  late FirebaseTypeRemoteDataSource dataSource;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final database = FirebaseDatabase.instance;
    database.useDatabaseEmulator('localhost', 9000);

    ref = database.ref('types_test');
    dataSource = FirebaseTypeRemoteDataSource(ref);
  });

  tearDown(() async {
    await ref.remove();
  });

  test('generateId returns a valid id', () async {
    final id = await dataSource.generateId();
    expect(id, isNotEmpty);
  });

  test('save and queryByType returns correct data', () async {
    final id = await dataSource.generateId();

    final data = {'type': 'food', 'name': 'Pizza'};

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

    final data = {'id': id,'type': 'food', 'name': 'Pizza'};

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

    await dataSource.save(id, {'type': 'drink', 'name': 'Coffee'});

    await dataSource.delete(id);

    final snapshot = await ref.child(id).get();
    expect(snapshot.exists, false);
  });

  test('watchTypes emits data changes', () async {
    final id = await dataSource.generateId();

    final stream = dataSource.watchTypes();

    await dataSource.save(id, {'type': 'snack', 'name': 'Burger'});

    final emitted = await stream.first as Map?;

    expect(emitted, isNotNull);
    expect(emitted![id]['name'], 'Burger');
  });
}
