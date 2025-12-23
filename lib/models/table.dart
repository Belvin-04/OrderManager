class Table1 {
  String id;
  int tableNo;

  Table1(this.tableNo, this.id);

  void setId(String id) {
    this.id = id;
  }

  String getId() => id;

  void setTableNo(int tableNo) {
    this.tableNo = tableNo;
  }

  int getTableNo() => tableNo;

  Map toMap() {
    Map tableMap = {};
    tableMap['id'] = id;
    tableMap['tableNo'] = tableNo;
    return tableMap;
  }

  static Table1 toTable(Map tableMap) {
    String id = tableMap['id'];
    int tableNo = tableMap['tableNo'];
    return Table1(tableNo, id);
  }

  @override
  String toString() {
    String tableDetails = "Id: $id\nTable No: $tableNo";
    return tableDetails;
  }
}
