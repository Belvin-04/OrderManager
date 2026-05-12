class BusinessEmployee {
  final String relationId;
  final String businessId;
  final String businessName;
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final String employeeRole;

  const BusinessEmployee({
    required this.relationId,
    required this.businessId,
    required this.businessName,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.employeeRole,
  });

  factory BusinessEmployee.fromMap(Map<String, dynamic> map) {
    return BusinessEmployee(
      relationId: map['relationId'] ?? '',
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      employeeEmail: map['employeeEmail'] ?? '',
      employeeRole: map['employeeRole'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'relationId': relationId,
      'businessId': businessId,
      'businessName': businessName,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeEmail': employeeEmail,
      'employeeRole': employeeRole,
    };
  }

  BusinessEmployee copyWith({
    String? relationId,
    String? businessId,
    String? businessName,
    String? employeeId,
    String? employeeName,
    String? employeeEmail,
    String? employeeRole,
  }) {
    return BusinessEmployee(
      relationId: relationId ?? this.relationId,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      employeeRole: employeeRole ?? this.employeeRole,
    );
  }

  @override
  String toString() {
    return '''BusinessEmployee(
      relationId: $relationId,
      businessId: $businessId,
      businessName: $businessName,
      employeeId: $employeeId,
      employeeName: $employeeName,
      employeeEmail: $employeeEmail,
      employeeRole: $employeeRole
    )''';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessEmployee &&
          other.relationId == relationId &&
          other.businessId == businessId &&
          other.businessName == businessName &&
          other.employeeId == employeeId &&
          other.employeeName == employeeName &&
          other.employeeEmail == employeeEmail &&
          other.employeeRole == employeeRole;

  @override
  int get hashCode =>
      relationId.hashCode ^
      businessId.hashCode ^
      businessName.hashCode ^
      employeeId.hashCode ^
      employeeName.hashCode ^
      employeeEmail.hashCode ^
      employeeRole.hashCode;
}
