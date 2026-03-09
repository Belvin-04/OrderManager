import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/repositories/firebase_table_repository.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {}

void main(){
    test('tableRepositoryProvider returns FirebaseTableRepository', () {
    final container = ProviderContainer(
      overrides: [tablesRefProvider.overrideWithValue(MockDatabaseReference())],
    );
    addTearDown(container.dispose);

    final repo = container.read(tableRepositoryProvider);

    expect(repo, isA<FirebaseTableRepository>());
  });
}
