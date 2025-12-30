import 'package:flutter/material.dart';

void showSnackBar(String message, ScaffoldMessengerState messanger) {
  SnackBar snackBar = SnackBar(content: Text(message));
  messanger.removeCurrentSnackBar();
  messanger.showSnackBar(snackBar);
}
