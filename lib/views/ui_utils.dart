import 'package:flutter/material.dart';

void showSnackBar(String message, BuildContext context) {
  SnackBar snackBar = SnackBar(content: Text(message));
  if (context.mounted) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
