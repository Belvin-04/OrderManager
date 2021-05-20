import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:order_manager/modal/Table.dart';
import 'package:order_manager/screens/Orders.dart';
import 'package:order_manager/utils/NavigationDrawer.dart';

class HomePage extends StatelessWidget {


  DatabaseReference tableReference = FirebaseDatabase.instance.reference().child("tables");
  List<Table_1> tableList = [];
  List tempList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavigationDrawer(),
      appBar: AppBar(
        title: Text("Home"),
      ),
      body: WillPopScope(
        onWillPop: (){

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
                        trailing: GestureDetector(
                          child: Icon(
                              Icons.event_note_outlined,
                              color: Colors.green
                          ),
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Orders(tableList[index])));
                          },
                        ),
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

}

