import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:order_manager/screens/tables.dart';
import 'package:order_manager/screens/items.dart';
import 'package:order_manager/screens/types.dart';

import 'ChangeThemeSwitch.dart';

class NavigationDrawer extends StatelessWidget {
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Items()));
              },
            ),
            Divider(
              color: Colors.white24,
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => Tables()));
              },
              title: Text("Tables"),
            ),
            Divider(
              color: Colors.white24,
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Types()));
              },
              title: Text("Types"),
            ),
            Divider(
              color: Colors.white24,
            ),
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
