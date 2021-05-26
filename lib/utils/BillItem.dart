import 'package:flutter/material.dart';

class BillItem extends StatelessWidget {
  final totalPrice, singlePrice, quantity;
  final name;
  BillItem(this.name, this.quantity, this.totalPrice, this.singlePrice);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: Text(name.toString())),
          Expanded(child: Center(child: Text(quantity.toString()))),
          Expanded(child: Center(child: Text(totalPrice.toString()))),
          Expanded(child: Center(child: Text(singlePrice.toString()))),
        ],
      ),
    );
  }
}
