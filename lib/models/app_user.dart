class AppUser {
  final String id;
  final String email;
  final String name;

  const AppUser({required this.id, required this.email, required this.name});

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'name': name};
  }

  AppUser copyWith({String? id, String? email, String? name}) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }

  @override
  String toString() {
    return "$name\n$email";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
