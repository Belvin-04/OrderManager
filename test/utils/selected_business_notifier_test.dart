import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/business.dart';
import 'package:order_manager/utils/selected_business_notifier.dart';

final testProvider = NotifierProvider<SelectedBusinessNotifier, Business?>(
  SelectedBusinessNotifier.new,
);

void main() {
  late ProviderContainer container;

  const business = Business(id: 'b1', name: 'Test Business', ownerId: 'owner1');

  setUp(() {
    container = ProviderContainer();

    addTearDown(container.dispose);
  });

  test('initial state is null', () {
    final result = container.read(testProvider);

    expect(result, isNull);
  });

  test('selectedBusiness setter updates state', () {
    final notifier = container.read(testProvider.notifier);

    notifier.selectedBusiness = business;

    final result = container.read(testProvider);

    expect(result, business);
  });

  test('selectedBusiness getter returns current state', () {
    final notifier = container.read(testProvider.notifier);

    notifier.selectedBusiness = business;

    expect(notifier.selectedBusiness, business);
  });

  test('clearBusiness resets state to null', () {
    final notifier = container.read(testProvider.notifier);

    notifier.selectedBusiness = business;

    expect(container.read(testProvider), business);

    notifier.clearBusiness();

    expect(container.read(testProvider), isNull);
  });

  test('can replace existing business', () {
    const secondBusiness = Business(
      id: 'b2',
      name: 'Second Business',
      ownerId: 'owner2',
    );

    final notifier = container.read(testProvider.notifier);

    notifier.selectedBusiness = business;

    expect(container.read(testProvider), business);

    notifier.selectedBusiness = secondBusiness;

    expect(container.read(testProvider), secondBusiness);
  });
}
