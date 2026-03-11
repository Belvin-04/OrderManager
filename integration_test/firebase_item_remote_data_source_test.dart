import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/firebase_options.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_item_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseReference ref;
  late FirebaseItemRemoteDataSource dataSource;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final database = FirebaseDatabase.instance;
    database.useDatabaseEmulator('localhost', 9000);

    ref = database.ref('items_test');
    dataSource = FirebaseItemRemoteDataSource(ref);
  });

  tearDown(() async {
    await ref.remove();
  });

  test('generateId returns a non-empty id', () async {
    final id = await dataSource.generateId();
    expect(id, isNotEmpty);
  });

  test('save and queryByName returns correct item', () async {
    final id = await dataSource.generateId();

    final item = {'name': 'Laptop', 'price': 1200};

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

    final item = {'id': id,'name': 'Laptop', 'price': 1200};

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

    await dataSource.save(id, {'name': 'Phone', 'price': 500});

    await dataSource.delete(id);

    final snapshot = await ref.child(id).get();
    expect(snapshot.exists, false);
  });

  test('watchItems emits when item is added', () async {
    final id = await dataSource.generateId();

    final stream = dataSource.watchItems();

    await dataSource.save(id, {'name': 'Tablet', 'price': 800});

    final emitted = await stream.first as Map?;

    expect(emitted, isNotNull);
    expect(emitted![id]['name'], 'Tablet');
  });
}
