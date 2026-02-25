import 'package:flutter/material.dart';
import 'package:order_manager/views/items/items.dart';
import 'package:order_manager/views/quick_orders.dart';
import 'package:order_manager/views/tables/tables.dart';
import 'package:order_manager/views/types/types.dart';

import 'change_theme_switch.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
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
