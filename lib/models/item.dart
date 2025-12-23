class Item {
  int price;
  String name;
  String id;

  Item(this.name, this.price, this.id);

  void setId(String id) {
    this.id = id;
  }

  String getId() {
    return id;
  }

  void setName(String name) {
    this.name = name;
  }

  String getName() {
    return name;
  }

  void setPrice(int price) {
    this.price = price;
  }

  int getPrice() {
    return price;
  }

  Map toMap() {
    Map itemMap = {};
    itemMap['name'] = name;
    itemMap['price'] = price;
    itemMap['id'] = id;
    return itemMap;
  }

  static Item toItem(Map itemMap) {
    String name = itemMap['name'];
    int price = itemMap['price'];
    String id = itemMap['id'];
    return Item(name, price, id);
  }

  @override
  String toString() {
    String itemDetails = "$name\n$price";
    return itemDetails;
  }

  Item copyWith({int? price, String? name, String? id}) {
    return Item(name ?? this.name, price ?? this.price, id ?? this.id);
  }
}
