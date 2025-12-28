class Table1 {
  final String id;
  final int tableNo;
  final int splitNo;

  Table1({required this.tableNo, required this.id, this.splitNo = 0});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> tableMap = {};
    tableMap['id'] = id;
    tableMap['tableNo'] = tableNo;
    tableMap['splitNo'] = splitNo;
    return tableMap;
  }

  factory Table1.fromMap(Map<String, dynamic> tableMap) {
    String id = tableMap['id'];
    int tableNo = tableMap['tableNo'];
    int splitNo = tableMap['splitNo'] ?? 0;
    return Table1(tableNo: tableNo, id: id, splitNo: splitNo);
  }

  Table1 copyWith({String? id, int? tableNo, int? splitNo}) {
    return Table1(
      tableNo: tableNo ?? this.tableNo,
      id: id ?? this.id,
      splitNo: splitNo ?? this.splitNo,
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
}
