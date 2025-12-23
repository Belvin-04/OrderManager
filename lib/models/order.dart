class Order {
  int quantity;
  String id;
  String itemName;
  int tableNo;
  String type;
  String status;
  String note;
  int amount;

  Order(
    this.quantity,
    this.id,
    this.itemName,
    this.tableNo,
    this.type,
    this.status,
    this.note,
    this.amount,
  );

  void setId(String id) {
    this.id = id;
  }

  String getId() => id;

  void setQuantity(int quantity) {
    this.quantity = quantity;
  }

  int getQuantity() => quantity;

  void setItemName(String itemName) {
    this.itemName = itemName;
  }

  String getItemName() => itemName;

  void setTableNo(int tableNo) {
    this.tableNo = tableNo;
  }

  int getTableId() => tableNo;

  void setType(String type) {
    this.type = type;
  }

  String getType(int flag) {
    if (type == "None" && flag == 0) {
      return "";
    }
    return type;
  }

  void setStatus(String status) {
    this.status = status;
  }

  String getStatus() => status;

  void setNote(String note) {
    this.note = note;
  }

  String getNote() => note;

  void setAmount(int amount) {
    this.amount = amount;
  }

  int getAmount() {
    return amount;
  }

  Map toMap() {
    Map orderMap = {};

    orderMap['id'] = id;
    orderMap['tableNo'] = tableNo;
    orderMap['itemName'] = itemName;
    orderMap['type'] = type;
    orderMap['quantity'] = quantity;
    orderMap['note'] = note;
    orderMap['status'] = status;
    orderMap['amount'] = amount;
    return orderMap;
  }

  static Order toOrder(Map orderMap) {
    String id, itemName, type, note, status;
    int tableNo, quantity, amount;

    id = orderMap['id'];
    tableNo = orderMap['tableNo'];
    itemName = orderMap['itemName'];
    type = orderMap['type'];
    quantity = orderMap['quantity'];
    note = orderMap['note'];
    status = orderMap['status'];
    amount = orderMap['amount'];

    return Order(quantity, id, itemName, tableNo, type, status, note, amount);
  }

  @override
  String toString() {
    String orderDetails =
        "Id: $id\nQuantity: $quantity\nItem Name: $itemName\nTable No: $tableNo\nType: $type\nNote: $note\nStatus: $status\nAmount: $amount";
    return orderDetails;
  }

  String getData() {
    String orderDetails = "Item Name: $itemName\n";
    if (type != "None") {
      orderDetails += "Type: $type\n";
    }
    orderDetails += "Quantity: $quantity\n";
    if (note != "") {
      orderDetails += "Note: $note";
    }
    return orderDetails;
  }

  Order copyWith({
    int? quantity,
    String? id,
    String? itemName,
    int? tableNo,
    String? type,
    String? status,
    String? note,
    int? amount,
  }) {
    return Order(
      quantity ?? this.quantity,
      id ?? this.id,
      itemName ?? this.itemName,
      tableNo ?? this.tableNo,
      type ?? this.type,
      status ?? this.status,
      note ?? this.note,
      amount ?? this.amount,
    );
  }
}
