class Type1 {
  final int price;
  final String type;
  final String id;
  final String businessId;

  Type1({
    required this.type,
    required this.price,
    required this.id,
    this.businessId = '',
  });

  String getType(int flag) {
    if (type == "None" && flag == 0) {
      return "";
    }
    return type;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> typeMap = {};
    typeMap['type'] = type;
    typeMap['price'] = price;
    typeMap['id'] = id;
    typeMap['businessId'] = businessId;
    return typeMap;
  }

  factory Type1.fromMap(Map<String, dynamic> typeMap) {
    String name = typeMap['type'];
    int price = typeMap['price'];
    String id = typeMap['id'];
    String businessId = typeMap['businessId'] ?? '';
    return Type1(type: name, price: price, id: id, businessId: businessId);
  }

  @override
  String toString() {
    String typeDetails = "$type\n$price";
    return typeDetails;
  }

  Type1 copyWith({String? id, int? price, String? type, String? businessId}) {
    return Type1(
      type: type ?? this.type,
      price: price ?? this.price,
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Type1 && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
