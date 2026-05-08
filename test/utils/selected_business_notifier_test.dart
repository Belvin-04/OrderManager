import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/utils/selected_business_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

final testProvider = NotifierProvider<SelectedBusinessNotifier, Business?>(
  SelectedBusinessNotifier.new,
);

void main() {
  late ProviderContainer container;

  const business = Business(id: 'b1', name: 'Test Business', ownerId: 'owner1');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('initial state is null', () {
    final result = container.read(testProvider);

    expect(result, isNull);
  });

  test('selectedBusiness setter function updates state', () async {
    final notifier = container.read(testProvider.notifier);

    await notifier.setSelectedBusiness(business);

    final result = container.read(testProvider);

    expect(result, business);
  });

  test('clearBusiness resets state to null', () async {
    final notifier = container.read(testProvider.notifier);

    await notifier.setSelectedBusiness(business);

    expect(container.read(testProvider), business);

    await notifier.clearBusiness();

    expect(container.read(testProvider), isNull);
  });

  test('can replace existing business', () async {
    const secondBusiness = Business(
      id: 'b2',
      name: 'Second Business',
      ownerId: 'owner2',
    );

    final notifier = container.read(testProvider.notifier);

    await notifier.setSelectedBusiness(business);

    expect(container.read(testProvider), business);

    await notifier.setSelectedBusiness(secondBusiness);

    expect(container.read(testProvider), secondBusiness);
  });

  test('setSelectedBusiness persists business to SharedPreferences', () async {
    final notifier = container.read(testProvider.notifier);

    await notifier.setSelectedBusiness(business);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('SelectedBusiness'), isNotNull);
    expect(prefs.getString('SelectedBusiness'), contains('b1'));
  });

  test(
    'setSelectedBusiness with null removes key from SharedPreferences',
    () async {
      final notifier = container.read(testProvider.notifier);

      await notifier.setSelectedBusiness(business);
      await notifier.setSelectedBusiness(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('SelectedBusiness'), isNull);
      expect(container.read(testProvider), isNull);
    },
  );

  test('clearBusiness removes key from SharedPreferences', () async {
    final notifier = container.read(testProvider.notifier);

    await notifier.setSelectedBusiness(business);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('SelectedBusiness'), isNotNull);

    await notifier.clearBusiness();

    expect(prefs.getString('SelectedBusiness'), isNull);
  });

  test('build restores persisted business from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({
      'SelectedBusiness':
          '{"id":"b1","name":"Test Business","ownerId":"owner1"}',
    });

    final freshContainer = ProviderContainer();
    addTearDown(freshContainer.dispose);

    freshContainer.read(testProvider.notifier);

    await Future.microtask(() {});
    await Future.microtask(() {});

    final restored = freshContainer.read(testProvider);
    expect(restored, isNotNull);
    expect(restored?.id, 'b1');
    expect(restored?.name, 'Test Business');
  });

  test('build returns null when no persisted business exists', () async {
    SharedPreferences.setMockInitialValues({});

    final freshContainer = ProviderContainer();
    addTearDown(freshContainer.dispose);

    freshContainer.read(testProvider.notifier);
    await Future.microtask(() {});
    await Future.microtask(() {});

    expect(freshContainer.read(testProvider), isNull);
  });
}
