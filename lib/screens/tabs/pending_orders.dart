import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/utils/firebase_service.dart';
import '../../modal/order.dart';
import '../../modal/table.dart';

class PendingOrders extends StatefulWidget {
  final Table1 table;

  PendingOrders({required this.table});

  @override
  State<PendingOrders> createState() => _PendingOrdersState();
}

class _PendingOrdersState extends State<PendingOrders> {
  final FirebaseService service = FirebaseService();
  final _formStateKey = GlobalKey<FormState>();
  late Table1 table;
  Map itemMap = Map();
  Map typeMap = Map();

  @override
  void initState() {
    super.initState();
    table = widget.table;
    showSaveOrderDialog(
        Order(0, "", "", table.getTableNo(), "", "pending", "", 0), 1);
  }

  @override
  Widget build(BuildContext context) {
    List orderList = [];
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: "Take New Order",
        child: Icon(Icons.add),
        onPressed: () {
          showSaveOrderDialog(
              Order(0, "", "", widget.table.getTableNo(), "", "pending", "", 0),
              0);
        },
      ),
      body: FutureBuilder(
          future: service.orderReference
              .orderByChild("tableNo")
              .equalTo(widget.table.getTableNo())
              .once(),
          builder: (context, snapshot) {
            orderList.clear();
            Map values = {};
            if (snapshot.data?.snapshot.value != null) {
              values = snapshot.data?.snapshot.value as Map<dynamic, dynamic>;
              values.forEach((key, value) {
                if (value['status'] == "pending") {
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
                            message: "Complete Order",
                            child: Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                          ),
                          onTap: () async {
                            await service.completeOrder(orderList[index]);
                            service.showSnackBar(
                                "Order Completed Successfully...", context);
                            updateList();
                          },
                        ),
                        Container(
                          height: 0,
                          width: 0,
                          margin: EdgeInsets.only(right: 10.0),
                        ),
                        GestureDetector(
                          child: Tooltip(
                            message: "Edit Order",
                            child: Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                          ),
                          onTap: () {
                            showSaveOrderDialog(orderList[index], 0);
                          },
                        ),
                        Container(
                          height: 0,
                          width: 0,
                          margin: EdgeInsets.only(right: 10.0),
                        ),
                        GestureDetector(
                          child: Tooltip(
                            message: "Cancel Order",
                            child: Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                          onTap: () async {
                            await service.cancelOrder(orderList[index]);
                            service.showSnackBar(
                                "Order Canceled Successfully...", context);
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

  showSaveOrderDialog(Order order, int flag) {
    String? itemNameDropDownValue1;
    String? itemTypeDropDownValue1;
    List itemNameDropDownList1 = [];
    List itemTypeDropDownList1 = [];
    TextEditingController itemQuantityController1 = TextEditingController();
    TextEditingController itemNoteController1 = TextEditingController();
    if (order.getQuantity() != 0) {
      itemQuantityController1.text = order.getQuantity().toString();
    }
    itemNoteController1.text = order.getNote();
    service.itemReference.once().then((value) {
      Map values = {};
      if (value.snapshot.value != null) {
        values = value.snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          itemNameDropDownList1.add(value['name']);
          itemMap[value['name']] = value['price'];
        });
        itemNameDropDownList1.sort();
        itemNameDropDownValue1 = itemNameDropDownList1[0];
        if (order.itemName != "") {
          itemNameDropDownValue1 = order.itemName;
        }

        service.typeReference.once().then((value) {
          Map typeValues = {};
          if (value.snapshot.value != null) {
            typeValues = value.snapshot.value as Map<dynamic, dynamic>;
            typeValues.forEach((key, value) {
              itemTypeDropDownList1.add(value['type']);
              typeMap[value['type']] = value['price'];
            });
            itemTypeDropDownList1.add("None");
            typeMap["None"] = 0;
            itemTypeDropDownValue1 = itemTypeDropDownList1[0];
          }
          if (order.type != "") {
            itemTypeDropDownValue1 = order.type;
          }
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                String itemNameDropDownValue = itemNameDropDownValue1!;
                String itemTypeDropDownValue = itemTypeDropDownValue1!;
                TextEditingController itemQuantityController =itemQuantityController1;
                TextEditingController itemNoteController = itemNoteController1;
                List itemNameDropDownList = itemNameDropDownList1;
                List itemTypeDropDownList = itemTypeDropDownList1;
                order.setItemName(itemNameDropDownValue);
                order.setType(itemTypeDropDownValue);
                if (order.getQuantity() != 0) {
                  itemQuantityController.text = order.getQuantity().toString();
                }
                itemNoteController.text = order.getNote();

                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                    title: Text("Order Detail"),
                    content: Container(
                      width: 200,
                      height: 270,
                      child: Form(
                        key: _formStateKey,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text("Item Name: ")),
                                Expanded(
                                  child: DropdownButton(
                                    isExpanded: true,
                                    items: itemNameDropDownList.map((value) {
                                      return DropdownMenuItem(
                                          value: value,
                                          child: Text(
                                            value,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ));
                                    }).toList(),
                                    value: itemNameDropDownValue,
                                    onChanged: (newValue) {
                                      order.setItemName(newValue.toString());
                                      print(order.getItemName());
                                      setState(() {
                                        itemNameDropDownValue =
                                            newValue.toString();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 0,
                              height: 0,
                              margin: EdgeInsets.only(bottom: 15.0),
                            ),
                            Row(
                              children: [
                                Expanded(child: Text("Item Type: ")),
                                Expanded(
                                  child: DropdownButton(
                                    isExpanded: true,
                                    items: itemTypeDropDownList.map((value) {
                                      return DropdownMenuItem(
                                          value: value,
                                          child: Text(
                                            value,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ));
                                    }).toList(),
                                    value: itemTypeDropDownValue,
                                    onChanged: (newValue) {
                                      order.setType(newValue.toString());
                                      print(order.getType(1));
                                      setState(() {
                                        itemTypeDropDownValue =
                                            newValue.toString();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 0,
                              height: 0,
                              margin: EdgeInsets.only(bottom: 15.0),
                            ),
                            TextFormField(
                              controller: itemQuantityController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Please Enter Quantity";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                  labelText: "Quantity",
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0))),
                              onChanged: (newQuantity) {
                                if (newQuantity.isNotEmpty) {
                                  order.setQuantity(int.parse(newQuantity));
                                }
                                print(order.getQuantity());
                              },
                            ),
                            Container(
                              width: 0,
                              height: 0,
                              margin: EdgeInsets.only(bottom: 15.0),
                            ),
                            TextFormField(
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              controller: itemNoteController,
                              decoration: InputDecoration(
                                  labelText: "Note",
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0))),
                              onChanged: (newNote) {
                                order.setNote(newNote);
                                print(order.getNote());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            if (_formStateKey.currentState!.validate()) {
                              await service.saveOrder(order);
                              Navigator.pop(context);
                              service.showSnackBar(
                                  "Order Saved Successfully...!", context);
                              updateList();
                            }
                          },
                          child: Text("Save Order"))
                    ],
                  );
                });
              });
          if (flag == 1) {
            Navigator.pop(context);
          }
        });
      }
    });
  }
}
