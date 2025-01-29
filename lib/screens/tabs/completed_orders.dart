import 'package:flutter/material.dart';
import 'package:order_manager/utils/firebase_service.dart';

import '../../modal/order.dart';
import '../../modal/table.dart';

class CompletedOrders extends StatefulWidget {
  final Table1 table;
  CompletedOrders({required this.table});

  @override
  State<CompletedOrders> createState() => _CompletedOrdersState();
}

class _CompletedOrdersState extends State<CompletedOrders> {
  final FirebaseService service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    List orderList = [];
    return FutureBuilder(
        future:
        service.orderReference.orderByChild("status").equalTo("completed").once(),
        builder: (context, snapshot) {
            orderList.clear();
            Map values = {};
            if (snapshot.data?.snapshot.value != null) {
              values = snapshot.data?.snapshot.value as Map<dynamic,dynamic>;
              values.forEach((key, value) {
                if (value['tableNo'] == widget.table.getTableNo()) {
                  orderList.add(Order.toOrder(value));
                }
              });
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: orderList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(orderList[index].getData()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          child: Tooltip(
                            message: "Repeat Order",
                            child: Icon(
                              Icons.replay_rounded,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () {
                            service.repeatOrder(orderList[index]);
                            service.showSnackBar(
                                "Order Repeated Successfully...", context);
                            updateList();

                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            );

        });
  }
  updateList() {
    setState(() {});
  }
}
