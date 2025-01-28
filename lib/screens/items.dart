import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/modal/item.dart';
import 'package:order_manager/utils/firebase_service.dart';

class Items extends StatefulWidget {
  @override
  _ItemsState createState() => _ItemsState();
}

class _ItemsState extends State<Items> {
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemPriceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FirebaseService service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    List<Item> itemList = [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Items"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Item",
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) =>
                  showAddItemDialog(Item("", 0, ""), context));
        },
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.pop(context);
          return Future.value(true);
        },
        child: FutureBuilder<DatabaseEvent>(
            future: service.itemReference.once(),
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.data?.snapshot.value != null) {
                itemList.clear();
                Map values = {};
                if (snapshot.data?.snapshot.value != null) {
                  values = snapshot.data?.snapshot.value as Map<dynamic,dynamic>;
                  values.forEach((key, values) {
                    itemList.add(Item.toItem(values));
                  });
                }

                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: itemList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        child: ListTile(
                          title: Text("Name: " + itemList[index].getName()),
                          subtitle: Text("Price: " +
                              itemList[index].getPrice().toString()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                child: Tooltip(
                                  message: "Edit Item",
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                ),
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          showAddItemDialog(
                                              itemList[index], context));
                                },
                              ),
                              Container(
                                margin: EdgeInsets.only(right: 10.0),
                              ),
                              GestureDetector(
                                child: Tooltip(
                                  message: "Delete Item",
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Delete Item ?"),
                                          content: Text(
                                              "This action cannot be undone..."),
                                          actions: [
                                            TextButton(
                                                child: Text("OK"),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  service.deleteItem(itemList[index]);
                                                  service.showSnackBar("Item Deleted Successfully", context);
                                                  updateListItem();
                                                })
                                          ],
                                        );
                                      });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    });
              }
              return Center(child: CircularProgressIndicator());
            }),
      ),
    );
  }

  void updateListItem(){
    setState(() {
    });
  }

  AlertDialog showAddItemDialog(Item item, BuildContext context) {
    itemNameController.text = item.getName();
    if (item.getPrice() != 0) {
      itemPriceController.text = item.getPrice().toString();
    } else {
      itemPriceController.text = "";
    }
    return AlertDialog(
      title: Text("Item Detail"),
      content: Container(
        width: 200,
        height: 150,
        child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextFormField(
                  onChanged: (name) {
                    item.setName(name);
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please Enter Product Name";
                    }

                    return null;
                  },
                  controller: itemNameController,
                  decoration: InputDecoration(
                      labelText: "Item Name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0))),
                ),
                Container(
                  width: 0.0,
                  height: 0.0,
                  margin: EdgeInsets.only(bottom: 10.0),
                ),
                TextFormField(
                  onChanged: (price) {
                    if (price.isNotEmpty) {
                      item.setPrice(int.parse(price));
                    }
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please Enter Product Price";
                    }
                    return null;
                  },
                  controller: itemPriceController,
                  decoration: InputDecoration(
                      labelText: "Item Price",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0))),
                ),
              ],
            )),
      ),
      actions: [
        TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await service.saveItem(item);
                itemPriceController.text = "";
                itemNameController.text = "";
                Navigator.pop(context);
                service.showSnackBar("Item Saved Successfully...", context);
                updateListItem();
              }
            },
            child: Text("Save Item"))
      ],
    );
  }
}
