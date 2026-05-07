class Item {
  final int price;
  final String name;
  final String id;
  final String businessId;

  Item({
    required this.name,
    required this.price,
    required this.id,
    this.businessId = '',
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> itemMap = {};
    itemMap['name'] = name;
    itemMap['price'] = price;
    itemMap['id'] = id;
    itemMap['businessId'] = businessId;
    return itemMap;
  }

  factory Item.fromMap(Map<String, dynamic> itemMap) {
    String name = itemMap['name'];
    int price = itemMap['price'];
    String id = itemMap['id'];
    String businessId = itemMap['businessId'] ?? '';
    return Item(name: name, price: price, id: id, businessId: businessId);
  }

  @override
  String toString() {
    String itemDetails = "$name\n$price";
    return itemDetails;
  }

  Item copyWith({int? price, String? name, String? id, String? businessId}) {
    return Item(
      name: name ?? this.name,
      price: price ?? this.price,
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Item && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
