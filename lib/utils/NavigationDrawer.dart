import 'package:flutter/material.dart';
import 'package:order_manager/screens/Tables.dart';
import 'package:order_manager/screens/Items.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ListTile(
              tileColor: Colors.white24,
              title: Text("Items"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Items()));
                //Navigator.push(context, MaterialPageRoute(builder:(context) => ViewAllItems() ));
              },
            ),
            Divider(
              color: Colors.white24,
            ),
            ListTile(
              tileColor: Colors.white24,
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => Tables()));
              },
              title: Text("Tables"),
            ),
            Divider(
              color: Colors.white24,
            ),
            ListTile(
              tileColor: Colors.white24,
              onTap: () {},
              title: Text("Bill"),
            )
          ],
        ),
      ),
    );
  }
}
