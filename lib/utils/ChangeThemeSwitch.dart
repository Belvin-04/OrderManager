import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ThemeProvider.dart';

class ChangeThemeSwitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeProvider darkThemeProvider = Provider.of<ThemeProvider>(context);
    return Switch.adaptive(
        value: darkThemeProvider.isdarkMode,
        onChanged: (value) {
          darkThemeProvider.darkTheme = value;
        });
  }
}
