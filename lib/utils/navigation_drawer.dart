import 'package:flutter/material.dart';
import 'package:order_manager/views/tables/tables.dart';
import 'package:order_manager/views/items/items.dart';
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
              title: Text("Items"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Items()),
                );
              },
            ),
            Divider(color: Colors.white24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Tables()),
                );
              },
              title: Text("Tables"),
            ),
            Divider(color: Colors.white24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Types()),
                );
              },
              title: Text("Types"),
            ),
            Divider(color: Colors.white24),
            ListTile(
              onTap: () {},
              title: Text("Dark Theme"),
              trailing: ChangeThemeSwitch(),
            ),
          ],
        ),
      ),
    );
  }
}
