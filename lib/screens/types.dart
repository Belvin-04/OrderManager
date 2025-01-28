import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/modal/type.dart';
import 'package:order_manager/utils/firebase_service.dart';

class Types extends StatefulWidget {
  @override
  _TypesState createState() => _TypesState();
}

class _TypesState extends State<Types> {
  TextEditingController typeNameController = TextEditingController();
  TextEditingController typePriceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FirebaseService service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    List<Type1> typeList = [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Types"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Type",
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) =>
                  showAddItemDialog(Type1("", 0, ""), context));
        },
      ),
      body: WillPopScope(
        onWillPop: () {
          Navigator.pop(context);
          return Future.value(true);
        },
        child: FutureBuilder<DatabaseEvent>(
            future: service.typeReference.once(),
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.data?.snapshot.value != null) {
                typeList.clear();
                Map values = {};
                if (snapshot.data?.snapshot.value != null) {
                  values = snapshot.data?.snapshot.value as Map<dynamic, dynamic>;
                  values.forEach((key, values) {
                    typeList.add(Type1.toType(values));
                  });
                }

                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: typeList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        child: ListTile(
                          title: Text("Type: " + typeList[index].getType()),
                          subtitle: Text("Price: " +
                              typeList[index].getPrice().toString()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                child: Tooltip(
                                  message: "Edit Type",
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
                                              typeList[index], context));
                                },
                              ),
                              Container(
                                margin: EdgeInsets.only(right: 10.0),
                              ),
                              GestureDetector(
                                child: Tooltip(
                                  message: "Delete Type",
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
                                          title: Text("Delete Type ?"),
                                          content: Text(
                                              "This action cannot be undone..."),
                                          actions: [
                                            TextButton(
                                                child: Text("OK"),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  service.deleteType(typeList[index]);
                                                  service.showSnackBar("Type Deleted Successfully", context);
                                                  updateTypeList();
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

  void updateTypeList() {
    setState(() {});
  }

  AlertDialog showAddItemDialog(Type1 type, BuildContext context) {
    typeNameController.text = type.getType();
    if (type.getPrice() != 0) {
      typePriceController.text = type.getPrice().toString();
    } else {
      typePriceController.text = "";
    }
    return AlertDialog(
      title: Text("Type Detail"),
      content: Container(
        width: 200,
        height: 130,
        child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextFormField(
                  onChanged: (name) {
                    type.setType(name);
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please Enter Type";
                    }

                    return null;
                  },
                  controller: typeNameController,
                  decoration: InputDecoration(
                      labelText: "Type Name",
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
                      type.setPrice(int.parse(price));
                    }
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please Enter Type Price";
                    }
                    return null;
                  },
                  controller: typePriceController,
                  decoration: InputDecoration(
                      labelText: "Type Price",
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
                await service.saveType(type);
                typePriceController.text = "";
                typeNameController.text = "";
                Navigator.pop(context);
                service.showSnackBar("Type Saved Successfully...", context);
                updateTypeList();
              }
            },
            child: Text("Save Type"))
      ],
    );
  }
}
