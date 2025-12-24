class Table1 {
  final String id;
  final int tableNo;

  Table1({required this.tableNo, required this.id});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> tableMap = {};
    tableMap['id'] = id;
    tableMap['tableNo'] = tableNo;
    return tableMap;
  }

  factory Table1.fromMap(Map<String, dynamic> tableMap) {
    String id = tableMap['id'];
    int tableNo = tableMap['tableNo'];
    return Table1(tableNo: tableNo, id: id);
  }

  @override
  String toString() {
    String tableDetails = "Id: $id\nTable No: $tableNo";
    return tableDetails;
  }
}
