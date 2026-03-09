import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/providers/item_providers.dart';
import 'package:order_manager/repositories/firebase_item_repository.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {}

void main(){
  test('itemRepositoryProvider returns FirebaseItemRepository', () {
    final container = ProviderContainer(
      overrides: [itemsRefProvider.overrideWithValue(MockDatabaseReference())],
    );
    addTearDown(container.dispose);

    final repo = container.read(itemRepositoryProvider);

    expect(repo, isA<FirebaseItemRepository>());
  });
}
