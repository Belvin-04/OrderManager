import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/views/employees/employees.dart';
import 'package:order_manager/views/items/items.dart';
import 'package:order_manager/views/quick_orders.dart';
import 'package:order_manager/views/tables/tables.dart';
import 'package:order_manager/views/types/types.dart';

import 'change_theme_switch.dart';

class NavigationDrawer extends ConsumerWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBusiness = ref.watch(selectedBusinessProvider);

    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text("Current Business"),
              subtitle: Text(selectedBusiness?.name ?? "Not selected"),
              leading: const Icon(Icons.store_mall_directory_outlined),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              title: const Text("Switch Business"),
              onTap: () {
                ref
                    .read(businessViewModelProvider.notifier)
                    .clearSelectedBusiness();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              title: const Text("Items"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Items()),
                );
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Tables()),
                );
              },
              title: const Text("Tables"),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Types()),
                );
              },
              title: const Text("Types"),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuickOrders()),
                );
              },
              title: const Text("Quick Orders"),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Employees()),
                );
              },
              title: const Text("Manage Employees"),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              onTap: () async {
                Navigator.pop(context);
                ref
                    .read(businessViewModelProvider.notifier)
                    .clearSelectedBusiness();
                await ref.read(authControllerProvider.notifier).signOut();
              },
              title: const Text("Logout"),
            ),
            const Divider(color: Colors.white24),
            const ListTile(
              title: Text("Dark Theme"),
              trailing: ChangeThemeSwitch(),
            ),
          ],
        ),
      ),
    );
  }
}
