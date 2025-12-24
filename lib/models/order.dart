class Order {
  final int quantity;
  final String id;
  final String itemName;
  final int tableNo;
  final String type;
  final String status;
  final String note;
  final int amount;

  Order({
    required this.quantity,
    required this.id,
    required this.itemName,
    required this.tableNo,
    required this.type,
    required this.status,
    required this.note,
    required this.amount,
  });

  String getType(int flag) {
    if (type == "None" && flag == 0) {
      return "";
    }
    return type;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> orderMap = {};

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

  factory Order.fromMap(Map<String, dynamic> orderMap) {
    String id;
    String itemName;
    String type;
    String note;
    String status;
    int tableNo;
    int quantity;
    int amount;

    id = orderMap['id'];
    tableNo = orderMap['tableNo'];
    itemName = orderMap['itemName'];
    type = orderMap['type'];
    quantity = orderMap['quantity'];
    note = orderMap['note'];
    status = orderMap['status'];
    amount = orderMap['amount'];

    return Order(
      quantity: quantity,
      id: id,
      itemName: itemName,
      tableNo: tableNo,
      type: type,
      status: status,
      note: note,
      amount: amount,
    );
  }

  @override
  String toString() {
    String orderDetails =
        """Id: $id\nQuantity: $quantity\nItem Name: $itemName\nTable No: $tableNo\nType: $type\nNote: $note\nStatus: $status\nAmount: $amount""";
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
      quantity: quantity ?? this.quantity,
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      tableNo: tableNo ?? this.tableNo,
      type: type ?? this.type,
      status: status ?? this.status,
      note: note ?? this.note,
      amount: amount ?? this.amount,
    );
  }
}
