import 'package:flutter/cupertino.dart';

import '../modal/order.dart';
import 'BillItem.dart';

class BillFooter extends StatelessWidget {
  final List<Order> orderList;
  BillFooter(this.orderList);
  @override
  Widget build(BuildContext context) {
    int totalAmount = 0;
    int totalQuantity = 0;
    orderList.forEach((element) {
      totalAmount += (element.getAmount());
      totalQuantity += (element.getQuantity());
    });
    return BillItem("", "$totalQuantity", "$totalAmount", "");
  }
}