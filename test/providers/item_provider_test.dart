import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/item_providers.dart';
import 'package:order_manager/repositories/firebase_item_repository.dart';

void main() {
  test('itemRepositoryProvider returns FirebaseItemRepository', () {
    final firestore = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        itemsRefProvider.overrideWithValue(firestore.collection('items')),
        currentBusinessIdProvider.overrideWithValue('business-test'),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(itemRepositoryProvider);

    expect(repo, isA<FirebaseItemRepository>());
  });
}
