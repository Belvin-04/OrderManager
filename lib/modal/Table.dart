class Table1 {
  String id;
  int tableNo;

  Table1(int tableNo, String id) {
    this.tableNo = tableNo;
    this.id = id;
  }

  void setId(String id) {
    this.id = id;
  }

  String getId() => this.id;

  void setTableNo(int tableNo) {
    this.tableNo = tableNo;
  }

  int geTableNo() => this.tableNo;

  Map toMap() {
    Map tableMap = new Map();
    tableMap['id'] = this.id;
    tableMap['tableNo'] = this.tableNo;
    return tableMap;
  }

  static Table1 toTable(Map tableMap) {
    String id = tableMap['id'];
    int tableNo = tableMap['tableNo'];
    return Table1(tableNo, id);
  }

  String toString() {
    String tableDetails = "Id: ${this.id}\nTable No: ${this.tableNo}";
    return tableDetails;
  }
}
