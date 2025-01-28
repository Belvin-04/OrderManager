import 'package:flutter/material.dart';
import 'package:order_manager/utils/firebase_service.dart';
import '../../modal/order.dart';
import '../../modal/table.dart';

class CancelledOrders extends StatefulWidget {
  final Table1 table;

  CancelledOrders({required this.table});

  @override
  State<CancelledOrders> createState() => _CancelledOrdersState();
}

class _CancelledOrdersState extends State<CancelledOrders> {
  final FirebaseService service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    List orderList = [];
    return Scaffold(
      body: FutureBuilder(
          future: service.orderReference
              .orderByChild("status")
              .equalTo("canceled")
              .once(),
          builder: (context, snapshot) {
            orderList.clear();
            Map values = {};
            if (snapshot.data?.snapshot.value != null) {
              values = snapshot.data?.snapshot.value as Map<dynamic, dynamic>;
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
                            message: "Restore Order",
                            child: Icon(
                              Icons.restore,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () async {
                            await service.restoreOrder(orderList[index]);
                            service.showSnackBar("Order Restored Successfully...", context);
                            updateList();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
    );
  }

  updateList() {
    setState(() {});
  }
}
