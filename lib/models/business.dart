class Business {
  final String id;
  final String name;
  final String ownerId;

  const Business({required this.id, required this.name, this.ownerId = ''});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'ownerId': ownerId};
  }

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
    );
  }

  Business copyWith({String? id, String? name, String? ownerId}) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  @override
  String toString() {
    return 'Business(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Business && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
