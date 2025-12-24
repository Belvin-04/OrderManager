import 'package:flutter/material.dart';

class BillItem extends StatelessWidget {
  final String totalPrice;
  final String singlePrice;
  final String quantity;
  final String name;
  const BillItem(
    this.name,
    this.quantity,
    this.totalPrice,
    this.singlePrice, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Expanded(child: Center(child: Text(quantity))),
          Expanded(child: Center(child: Text(totalPrice))),
          Expanded(child: Center(child: Text(singlePrice))),
        ],
      ),
    );
  }
}
