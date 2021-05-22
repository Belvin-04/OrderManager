import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/modal/Item.dart';

class Items extends StatefulWidget {
  final FirebaseApp app;
  Items(this.app);

  @override
  _ItemsState createState() => _ItemsState(app);
}

class _ItemsState extends State<Items> {
  FirebaseApp app;
  _ItemsState(this.app);
  DatabaseReference itemReference;
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemPriceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FirebaseDatabase database;
  @override
  void initState() {
    super.initState();
    database = FirebaseDatabase(app: app);
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    itemReference = database.reference().child("items");
    itemReference.keepSynced(true);
  }

  @override
  Widget build(BuildContext context) {
    List<Item> itemList = [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Items"),
      ),
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
        child: FutureBuilder(
            future: itemReference.once(),
            builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
              if (snapshot.hasData) {
                itemList.clear();
                Map values = snapshot.data.value;
                if (values != null) {
                  values.forEach((key, values) {
                    itemList.add(Item.toItem(values));
                  });
                }

                return new ListView.builder(
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
                                                  _delete(
                                                      context, itemList[index]);
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

  void _delete(BuildContext context, Item item) {
    String id = item.getId();

    DatabaseReference itemReference1 = itemReference.child(id);
    itemReference1.remove();
    updateItemList();
    showSnackBar("Item Deleted Successfully", context);
  }

  void updateItemList() {
    setState(() {});
  }

  void showSnackBar(String message, BuildContext context) {
    SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
      content: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextFormField(
                onChanged: (name) {
                  item.setName(name);
                },
                validator: (value) {
                  if (value.isEmpty) {
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
                  if (value.isEmpty) {
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
      actions: [
        TextButton(
            onPressed: () {
              if (_formKey.currentState.validate()) {
                saveItem(item);
                itemPriceController.text = "";
                itemNameController.text = "";
                Navigator.pop(context);
                showSnackBar("Item Saved Successfully...", context);
              }
            },
            child: Text("Save Item"))
      ],
    );
  }

  void saveItem(Item item) {
    itemReference
        .orderByChild("name")
        .equalTo(item.getName())
        .once()
        .then((value) {
      String id = item.getId();
      if (id.isEmpty) {
        id = itemReference.push().key;
      } else {
        id = item.getId();
      }
      Map itemMap = item.toMap();
      itemMap['id'] = id;

      if (value != null) {
        Map values = value.value;
        if (values != null) {
          values.forEach((key, value) {
            itemMap['id'] = value['id'];
          });
        }
        itemReference.child(itemMap['id']).set(itemMap);
        updateItemList();
      }
    });
  }
}
