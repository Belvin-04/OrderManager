import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/providers/type_providers.dart';
import 'package:order_manager/repositories/firebase_type_repository.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {}

void main() {
  test('typeRepositoryProvider returns FirebaseTypeRepository', () {
    final container = ProviderContainer(
      overrides: [typesRefProvider.overrideWithValue(MockDatabaseReference())],
    );
    addTearDown(container.dispose);

    final repo = container.read(typeRepositoryProvider);

    expect(repo, isA<FirebaseTypeRepository>());
  });
}
