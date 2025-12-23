import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/providers/providers.dart';

class ChangeThemeSwitch extends ConsumerWidget {
  const ChangeThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Switch.adaptive(
      value: themeMode == ThemeMode.dark,
      onChanged: notifier.toggleTheme,
    );
  }
}
