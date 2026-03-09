import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/utils/startup_screen_provider.dart';
import 'package:order_manager/utils/theme_provider.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

final startupScreenProvider =
    NotifierProvider<StartupScreenNotifier, StartupScreen>(() {
      return StartupScreenNotifier();
    });
