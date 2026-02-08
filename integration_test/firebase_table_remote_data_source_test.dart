import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/firebase_options.dart';
import 'package:order_manager/repositories/remote_data_source/firebase_table_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseReference ref;
  late FirebaseTableRemoteDataSource dataSource;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final database = FirebaseDatabase.instance;
    database.useDatabaseEmulator('localhost', 9000);

    ref = database.ref('tables_test');
    dataSource = FirebaseTableRemoteDataSource(ref);
  });

  tearDown(() async {
    await ref.remove();
  });

  test('generateId returns a non-empty id', () async {
    final id = await dataSource.generateId();
    expect(id, isNotEmpty);
  });

  test('save and watchTables emits data', () async {
    final id = await dataSource.generateId();

    final stream = dataSource.watchTables();

    await dataSource.save(id, {'tableNo': 1, 'capacity': 4});

    final emitted = await stream.first as Map?;

    expect(emitted, isNotNull);
    expect(emitted![id]['capacity'], 4);
  });

  test('getLastTable returns table with highest tableNo', () async {
    await dataSource.save('t1', {'tableNo': 1, 'capacity': 2});

    await dataSource.save('t2', {'tableNo': 3, 'capacity': 6});

    await dataSource.save('t3', {'tableNo': 2, 'capacity': 4});

    final result = await dataSource.getLastTable() as Map?;

    expect(result, isNotNull);

    final table = result!.values.first;
    expect(table['tableNo'], 3);
    expect(table['capacity'], 6);
  });

  test('updatePosition updates only position field', () async {
    final id = await dataSource.generateId();

    await dataSource.save(id, {
      'tableNo': 5,
      'capacity': 4,
      'position': {'x': 0, 'y': 0},
    });

    await dataSource.updatePosition(id, {'x': 10, 'y': 20});

    final snapshot = await ref.child(id).get();
    final data = snapshot.value as Map;

    expect(data['tableNo'], 5);
    expect(data['capacity'], 4);
    expect(data['position']['x'], 10);
    expect(data['position']['y'], 20);
  });

  test('delete removes table from database', () async {
    final id = await dataSource.generateId();

    await dataSource.save(id, {'tableNo': 9, 'capacity': 8});

    await dataSource.delete(id);

    final snapshot = await ref.child(id).get();
    expect(snapshot.exists, false);
  });
}
