import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:order_manager/screens/Tables.dart';
import 'package:order_manager/screens/Items.dart';
import 'package:order_manager/screens/Types.dart';

import 'ChangeThemeSwitch.dart';

class NavigationDrawer extends StatelessWidget {
  final FirebaseApp app;
  NavigationDrawer(this.app);

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
                    MaterialPageRoute(builder: (context) => Items(app)));
              },
            ),
            Divider(
              color: Colors.white24,
            ),
            ListTile(
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => Tables(app)));
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
                    MaterialPageRoute(builder: (context) => Types(app)));
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
