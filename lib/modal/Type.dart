class Type1 {
  int price;
  String type;
  String id;

  Type1(String type, int price, String id) {
    this.type = type;
    this.price = price;
    this.id = id;
  }

  void setId(String id) {
    this.id = id;
  }

  String getId() {
    return this.id;
  }

  void setType(String type) {
    this.type = type;
  }

  String getType() {
    return this.type;
  }

  void setPrice(int price) {
    this.price = price;
  }

  int getPrice() {
    return this.price;
  }

  Map toMap() {
    Map typeMap = Map();
    typeMap['type'] = this.type;
    typeMap['price'] = this.price;
    typeMap['id'] = this.id;
    return typeMap;
  }

  static Type1 toType(Map typeMap) {
    String name = typeMap['type'];
    int price = typeMap['price'];
    String id = typeMap['id'];
    return Type1(name, price, id);
  }

  String toString() {
    String typeDetails = "${this.type}\n${this.price}";
    return typeDetails;
  }
}
