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
  final String businessId;

  Order({
    required this.quantity,
    required this.id,
    required this.item,
    required this.table,
    required this.type,
    required this.status,
    required this.note,
    required this.amount,
    this.businessId = '',
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
    orderMap['businessId'] = businessId;
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
    String businessId;

    id = orderMap['id'];
    table = Table1.fromMap(Map<String, dynamic>.from(orderMap['table']));
    item = Item.fromMap(Map<String, dynamic>.from(orderMap['item']));
    type = Type1.fromMap(Map<String, dynamic>.from(orderMap['type']));
    quantity = orderMap['quantity'];
    note = orderMap['note'];
    status = orderMap['status'];
    amount = orderMap['amount'];
    businessId = orderMap['businessId'] ?? '';

    return Order(
      quantity: quantity,
      id: id,
      item: item,
      table: table,
      type: type,
      status: status,
      note: note,
      amount: amount,
      businessId: businessId,
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
    String? businessId,
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
      businessId: businessId ?? this.businessId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Order && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
