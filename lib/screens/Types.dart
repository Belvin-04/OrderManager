import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:order_manager/modal/Type.dart';

class Types extends StatefulWidget {
  final FirebaseApp app;
  Types(this.app);

  @override
  _TypesState createState() => _TypesState(app);
}

class _TypesState extends State<Types> {
  FirebaseApp app;
  _TypesState(this.app);
  DatabaseReference typeReference;
  TextEditingController typeNameController = TextEditingController();
  TextEditingController typePriceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FirebaseDatabase database;
  @override
  void initState() {
    super.initState();
    database = FirebaseDatabase(app: app);
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    typeReference = database.reference().child("types");
    typeReference.keepSynced(true);
  }

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
        child: FutureBuilder(
            future: typeReference.once(),
            builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
              if (snapshot.hasData) {
                typeList.clear();
                Map values = snapshot.data.value;
                if (values != null) {
                  values.forEach((key, values) {
                    typeList.add(Type1.toType(values));
                  });
                }

                return new ListView.builder(
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
                                                  _delete(
                                                      context, typeList[index]);
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

  void _delete(BuildContext context, Type1 type) {
    String id = type.getId();

    DatabaseReference typeReference1 = typeReference.child(id);
    typeReference1.remove();
    updateTypeList();
    showSnackBar("Type Deleted Successfully", context);
  }

  void updateTypeList() {
    setState(() {});
  }

  void showSnackBar(String message, BuildContext context) {
    SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
                    if (value.isEmpty) {
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
                    if (value.isEmpty) {
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
            onPressed: () {
              if (_formKey.currentState.validate()) {
                saveType(type);
                typePriceController.text = "";
                typeNameController.text = "";
                Navigator.pop(context);
                showSnackBar("Type Saved Successfully...", context);
              }
            },
            child: Text("Save Type"))
      ],
    );
  }

  void saveType(Type1 type) {
    typeReference
        .orderByChild("type")
        .equalTo(type.getType())
        .once()
        .then((value) {
      String id = type.getId();
      if (id.isEmpty) {
        id = typeReference.push().key;
      } else {
        id = type.getId();
      }
      Map typeMap = type.toMap();
      typeMap['id'] = id;

      if (value != null) {
        Map values = value.value;
        if (values != null) {
          values.forEach((key, value) {
            typeMap['id'] = value['id'];
          });
        }
        typeReference.child(typeMap['id']).set(typeMap);
        updateTypeList();
      }
    });
  }
}
