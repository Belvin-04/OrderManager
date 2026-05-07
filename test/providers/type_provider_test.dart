import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/type_providers.dart';
import 'package:order_manager/repositories/firebase_type_repository.dart';

void main() {
  test('typeRepositoryProvider returns FirebaseTypeRepository', () {
    final firestore = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        typesRefProvider.overrideWithValue(firestore.collection('types')),
        currentBusinessIdProvider.overrideWithValue('business-test'),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(typeRepositoryProvider);

    expect(repo, isA<FirebaseTypeRepository>());
  });
}
