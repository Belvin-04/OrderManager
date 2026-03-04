import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StartupScreen { home, tableLayout }

class StartupScreenNotifier extends Notifier<StartupScreen> {
  static const _startupScreenKey = 'startupScreen';
  static const _tableLayoutValue = 'table_layout';
  static const _homeValue = 'home';

  @override
  StartupScreen build() {
    _loadStartupScreen();
    return StartupScreen.home;
  }

  Future<void> _loadStartupScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final screen = prefs.getString(_startupScreenKey);

    state = screen == _tableLayoutValue
        ? StartupScreen.tableLayout
        : StartupScreen.home;
  }

  Future<void> setStartupScreen(StartupScreen screen) async {
    state = screen;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _startupScreenKey,
      screen == StartupScreen.tableLayout ? _tableLayoutValue : _homeValue,
    );
  }
}
