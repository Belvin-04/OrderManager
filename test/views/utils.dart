import 'package:flutter/material.dart';
import 'package:order_manager/utils/theme_provider.dart';

class FakeThemeNotifier extends ThemeNotifier {
  final ThemeMode initialMode;

  FakeThemeNotifier(this.initialMode);

  @override
  ThemeMode build() {
    return initialMode;
  }
}
