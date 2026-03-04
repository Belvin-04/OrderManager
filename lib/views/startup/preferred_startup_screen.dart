import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/utils/startup_screen_provider.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';

class PreferredStartupScreen extends ConsumerWidget {
  const PreferredStartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupScreen = ref.watch(startupScreenProvider);

    if (startupScreen == StartupScreen.tableLayout) {
      return TableLayoutScreen();
    }
    return HomePage();
  }
}
