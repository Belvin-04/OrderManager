import 'package:flutter/services.dart';

class Table1 {
  final String id;
  final int tableNo;
  final int splitNo;
  final Offset position;
  final String businessId;

  Table1({
    required this.tableNo,
    required this.id,
    this.splitNo = 0,
    this.position = const Offset(100, 100),
    this.businessId = '',
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> tableMap = {};
    tableMap['id'] = id;
    tableMap['tableNo'] = tableNo;
    tableMap['splitNo'] = splitNo;
    tableMap['position'] = position.toMap();
    tableMap['businessId'] = businessId;
    return tableMap;
  }

  factory Table1.fromMap(Map<String, dynamic> tableMap) {
    String id = tableMap['id'];
    int tableNo = tableMap['tableNo'];
    int splitNo = tableMap['splitNo'] ?? 0;
    String businessId = tableMap['businessId'] ?? '';
    Offset position = fromOffsetMap(
      Map<String, dynamic>.from(tableMap['position']),
    );
    return Table1(
      tableNo: tableNo,
      id: id,
      splitNo: splitNo,
      position: position,
      businessId: businessId,
    );
  }

  Table1 copyWith({
    String? id,
    int? tableNo,
    int? splitNo,
    Offset? position,
    String? businessId,
  }) {
    return Table1(
      tableNo: tableNo ?? this.tableNo,
      id: id ?? this.id,
      splitNo: splitNo ?? this.splitNo,
      position: position ?? this.position,
      businessId: businessId ?? this.businessId,
    );
  }

  @override
  String toString() {
    String tableDetails = "Id: $id\nTable No: $tableNo";
    return tableDetails;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Table1 && other.id == id;

  @override
  int get hashCode => id.hashCode;

  static Offset fromOffsetMap(Map<String, dynamic> map) {
    return Offset(
      double.parse(map["x"].toString()),
      double.parse(map["y"].toString()),
    );
  }
}

extension OffsetToMap on Offset {
  Map<String, double> toMap() {
    Map<String, double> position = {};
    position["x"] = dx;
    position["y"] = dy;
    return position;
  }
}
