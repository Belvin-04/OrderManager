import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/utils_provider.dart';
import 'package:order_manager/utils/startup_screen_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('default startup screen is home', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(startupScreenProvider), StartupScreen.home);
  });

  test('setStartupScreen updates state and saves preference', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(startupScreenProvider.notifier)
        .setStartupScreen(StartupScreen.tableLayout);

    final prefs = await SharedPreferences.getInstance();

    expect(container.read(startupScreenProvider), StartupScreen.tableLayout);
    expect(prefs.getString('startupScreen'), 'table_layout');
  });

  test('loads saved startup screen preference', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'startupScreen': 'table_layout'});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(startupScreenProvider);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(container.read(startupScreenProvider), StartupScreen.tableLayout);
  });
}
