import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';

class Order {
  final int quantity;
  final String id;
  final Item item;
  final Table1 table;
  final Type1 type;
  final String status;
  final String note;
  final int amount;

  Order({
    required this.quantity,
    required this.id,
    required this.item,
    required this.table,
    required this.type,
    required this.status,
    required this.note,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> orderMap = {};

    orderMap['id'] = id;
    orderMap['table'] = table.toMap();
    orderMap['item'] = item.toMap();
    orderMap['type'] = type.toMap();
    orderMap['quantity'] = quantity;
    orderMap['note'] = note;
    orderMap['status'] = status;
    orderMap['amount'] = amount;
    return orderMap;
  }

  factory Order.fromMap(Map<dynamic, dynamic> orderMap) {
    String id;
    Item item;
    Type1 type;
    String note;
    String status;
    Table1 table;
    int quantity;
    int amount;

    id = orderMap['id'];
    table = Table1.fromMap(Map<String, dynamic>.from(orderMap['table']));
    item = Item.fromMap(Map<String, dynamic>.from(orderMap['item']));
    type = Type1.fromMap(Map<String, dynamic>.from(orderMap['type']));
    quantity = orderMap['quantity'];
    note = orderMap['note'];
    status = orderMap['status'];
    amount = orderMap['amount'];

    return Order(
      quantity: quantity,
      id: id,
      item: item,
      table: table,
      type: type,
      status: status,
      note: note,
      amount: amount,
    );
  }

  @override
  String toString() {
    String orderDetails =
        """Id: $id\nQuantity: $quantity\nItem Name: ${item.name}\nTable No: ${table.tableNo}\nType: ${type.type}\nNote: $note\nStatus: $status\nAmount: $amount""";
    return orderDetails;
  }

  String getData() {
    String orderDetails = "Item Name: ${item.name}\n";
    if (type.type != "None") {
      orderDetails += "Type: ${type.type}\n";
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
    Item? item,
    Table1? table,
    Type1? type,
    String? status,
    String? note,
    int? amount,
  }) {
    return Order(
      quantity: quantity ?? this.quantity,
      id: id ?? this.id,
      item: item ?? this.item,
      table: table ?? this.table,
      type: type ?? this.type,
      status: status ?? this.status,
      note: note ?? this.note,
      amount: amount ?? this.amount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Order && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
