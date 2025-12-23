class Type1 {
  int price;
  String type;
  String id;

  Type1(this.type, this.price, this.id) {
    type = type;
    price = price;
    id = id;
  }

  void setId(String id) {
    this.id = id;
  }

  String getId() {
    return id;
  }

  void setType(String type) {
    this.type = type;
  }

  String getType() {
    return type;
  }

  void setPrice(int price) {
    this.price = price;
  }

  int getPrice() {
    return price;
  }

  Map toMap() {
    Map typeMap = {};
    typeMap['type'] = type;
    typeMap['price'] = price;
    typeMap['id'] = id;
    return typeMap;
  }

  static Type1 toType(Map typeMap) {
    String name = typeMap['type'];
    int price = typeMap['price'];
    String id = typeMap['id'];
    return Type1(name, price, id);
  }

  @override
  String toString() {
    String typeDetails = "$type\n$price";
    return typeDetails;
  }

  Type1 copyWith({String? id, int? price, String? type}) {
    return Type1(type ?? this.type, price ?? this.price, id ?? this.id);
  }
}
