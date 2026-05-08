import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/repositories/abstract_files/business_repository.dart';

class BusinessViewModel extends AsyncNotifier<void> {
  late BusinessRepository _repo;
  @override
  Future<void> build() async {
    _repo = ref.read(businessRepositoryProvider);
  }

  Future<void> saveBusiness(Business business) async {
    _repo = ref.read(businessRepositoryProvider);
    final ownerId = ref.read(currentUserIdProvider) ?? '';
    final businessToSave = business.copyWith(ownerId: ownerId);
    final savedBusiness = await _repo.saveBusiness(businessToSave);
    await ref
        .read(selectedBusinessProvider.notifier)
        .setSelectedBusiness(savedBusiness);
  }

  Future<void> deleteBusiness(Business business) async {
    _repo = ref.read(businessRepositoryProvider);
    await _deleteBusinessCollections(business.id);
    await _repo.deleteBusiness(business);

    final selected = ref.read(selectedBusinessProvider);
    if (selected?.id == business.id) {
      await ref.read(selectedBusinessProvider.notifier).clearBusiness();
    }
  }

  void clearSelectedBusiness() {
    _repo = ref.read(businessRepositoryProvider);
    ref.read(selectedBusinessProvider.notifier).clearBusiness();
  }

  Future<void> _deleteBusinessCollections(String businessId) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(businessRepositoryProvider);

      await repo.deleteBusinessCollections(businessId);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
