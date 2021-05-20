class Order{
  int quantity;
  String id;
  String itemName;
  int tableNo;
  String type;
  String status;
  String note;

  Order(this.quantity, this.id, this.itemName, this.tableNo, this.type,this.status,this.note);


  void setId(String id){
    this.id = id;
  }
  String getId() => this.id;

  void setQuantity(int quantity){
    this.quantity = quantity;
  }
  int getQuantity() => this.quantity;

  void setItemName(String itemName){
    this.itemName = itemName;
  }

  String getItemName() => this.itemName;

  void setTableNo(int tableNo){
    this.tableNo = tableNo;
  }

  int getTableId() => this.tableNo;

  void setType(String type){
    this.type = type;
  }

  String getType() => this.type;

  void setStatus(String status){
    this.status = status;
  }

  String getStatus() => this.status;

  void setNote(String note){
    this.note = note;
  }

  String getNote() => this.note;


  Map toMap(){
    Map orderMap = new Map();

    orderMap['id'] = this.id;
    orderMap['tableNo'] = this.tableNo;
    orderMap['itemName'] = this.itemName;
    orderMap['type'] = this.type;
    orderMap['quantity'] = this.quantity;
    orderMap['note'] = this.note;
    orderMap['status'] = this.status;


    return orderMap;
  }
  static Order toOrder(Map orderMap){
    String id,itemName,type,note,status;
    int tableNo,quantity;

    id = orderMap['id'];
    tableNo = orderMap['tableNo'];
    itemName = orderMap['itemName'];
    type = orderMap['type'];
    quantity = orderMap['quantity'];
    note = orderMap['note'];
    status = orderMap['status'];

    return Order(quantity,id,itemName,tableNo,type,status,note);
  }


  String toString(){
    String orderDetails = "Id: ${this.id}\nQuantity: ${this.quantity}\nItem Name: ${this.itemName}\nTable No: ${this.tableNo}\nType: ${this.type}\nNote: ${this.note}\nStatus: ${this.status}";
    return orderDetails;
  }
}