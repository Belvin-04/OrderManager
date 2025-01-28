import 'package:flutter/material.dart';
import 'package:order_manager/modal/order.dart';
import 'package:order_manager/modal/table.dart';
import 'package:order_manager/utils/BillItem.dart';
import 'package:order_manager/utils/firebase_service.dart';

import '../utils/bill_footer.dart';

class Bills extends StatefulWidget {
  final Table1 table;

  Bills(this.table);

  @override
  _BillsState createState() => _BillsState();
}

class _BillsState extends State<Bills> {
  late Future<List<Order>> orderList;
  FirebaseService service = FirebaseService();

  @override
  void initState() {
    super.initState();
    orderList = service.getTableOrders(widget.table);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Table ${widget.table.getTableNo()}: Bill"),
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.pop(context);
          return Future.value(true);
        },
        child: ListView(
          shrinkWrap: true,
          children: [
            Center(
              child: Text(
                "Invoice",
                style: TextStyle(fontSize: 30),
              ),
            ),
            Divider(
              color: Colors.white,
            ),
            BillItem("Name", "Quantity", "Total Price", "Single Price"),
            Divider(
              color: Colors.white,
            ),
            FutureBuilder(
                future: orderList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No orders found.'));
                  } else {
                    List<Order> orders = snapshot.data!;
                    return Column(
                      children: [
                        ListView.builder(
                            shrinkWrap: true,
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              return BillItem(
                                  "${orders[index].getItemName()} ${orders[index].getType(0)}",
                                  "${orders[index].getQuantity()}",
                                  "${orders[index].getAmount()}",
                                  "${(orders[index].getAmount() / orders[index].getQuantity())}");
                            }),
                        Divider(
                          color: Colors.white,
                        ),
                        BillFooter(orders)
                      ],
                    );
                  }
                }),
          ],
        ),
      ),
    );
  }
}
