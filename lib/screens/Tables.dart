import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:order_manager/utils/NavigationDrawer.dart';
import 'package:order_manager/modal/Table.dart';

import 'HomePage.dart';

class Tables extends StatefulWidget {
  const Tables({Key key}) : super(key: key);

  @override
  _TablesState createState() => _TablesState();
}

class _TablesState extends State<Tables> {

  DatabaseReference tableReference = FirebaseDatabase.instance.reference().child("tables");
  List<Table_1> tableList = [];
  List tempList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            FloatingActionButton(child: Icon(Icons.delete,color: Colors.white,),onPressed: (){
              removeTable();
            },
              backgroundColor: Colors.red,
            ),
            Container(width: 0,height: 0,margin: EdgeInsets.only(right: 10.0),),
            FloatingActionButton(child: Icon(Icons.add,color: Colors.white,),onPressed: (){
              addTable();
            },
              backgroundColor: Colors.red,
            ),
        ],
      ),
      appBar: AppBar(
        title: Text("Manage Tables"),
      ),
      body: WillPopScope(
        onWillPop: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
        },
        child: FutureBuilder(
          future: tableReference.once(),
          builder: (context, AsyncSnapshot<DataSnapshot> snapshot){
            if(snapshot.hasData){
              tableList.clear();
              tempList.clear();
              Map values = snapshot.data.value;
              if(values != null){
                values.forEach((key, value) {
                  tempList.add(Table_1.toTable(value));
                });

                for(int i=0 ;i<tempList.length;i++){
                  tableList.add(Table_1(0,""));
                }

                values.forEach((key, value) {
                  tableList[value['tableNo']-1] = Table_1.toTable(value);
                  //tableList.add(Table_1.toTable(value));
                });
              }

              return ListView.builder(
                  itemCount: tableList.length,
                  itemBuilder: (BuildContext context,int index){
                return Card(
                  child: ListTile(
                    title: Text("Table No. : ${tableList[index].geTableNo()}"),
                  ),
                );
              });

            }
            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void addTable(){
    int tableNo = 0;
    Query tableNoQuery = tableReference.orderByChild('tableNo').limitToLast(1);
    tableNoQuery.once().then((value) {
      Map values = value.value;
      if(values == null){
        tableNo++;
      }
      else{
        values.forEach((key, value) {
          tableNo = value['tableNo'];
          tableNo++;
        });
      }
      String id = tableReference.push().key;
      Map tableMap = Table_1(tableNo,id).toMap();
      tableReference.child(id).set(tableMap);
      updateListView();
      showSnackBar("Table added successfully...", context);
    });
  }

  void removeTable(){
    String tableId;
    Query tableNoQuery = tableReference.orderByChild('tableNo').limitToLast(1);
    tableNoQuery.once().then((value) {
      Map values = value.value;
      if(values == null){
        showSnackBar("No Tables found...", context);
      }
      else{

        values.forEach((key, value) {
          tableId = key;
        });
        DatabaseReference tableReference = FirebaseDatabase.instance.reference().child("tables").child(tableId);
        tableReference.remove();
        updateListView();
        showSnackBar("Table removed successfully...", context);
      }
    });
  }

  updateListView(){
    setState(() {

    });
  }

  void showSnackBar(String message,BuildContext context){
    SnackBar snackBar = SnackBar(content: Text(message));
    //Scaffold.of(context).showSnackBar(snackBar);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
