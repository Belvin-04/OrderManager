import 'package:flutter/material.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart'
    show TableOrderStatus;

void showSnackBar(String message, ScaffoldMessengerState messanger) {
  SnackBar snackBar = SnackBar(content: Text(message));
  messanger.removeCurrentSnackBar();
  messanger.showSnackBar(snackBar);
}

Color? getBackgroundColor(TableOrderStatus tableOrderStatus) {
  if (tableOrderStatus == TableOrderStatus.pending) {
    return Colors.orange[900];
  }
  if (tableOrderStatus == TableOrderStatus.completed) {
    return Colors.green[900];
  }
  if (tableOrderStatus == TableOrderStatus.canceled) {
    return Colors.red[900];
  }
  return null;
}
