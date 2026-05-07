import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/repositories/firebase_table_repository.dart';

void main() {
  test('tableRepositoryProvider returns FirebaseTableRepository', () {
    final firestore = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        tablesRefProvider.overrideWithValue(firestore.collection('tables')),
        currentBusinessIdProvider.overrideWithValue('business-test'),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(tableRepositoryProvider);

    expect(repo, isA<FirebaseTableRepository>());
  });
}
