class LendPerson {
  final int? id;
  final String name;
  final String? phoneNumber;
  final int createdAt;

  const LendPerson({
    this.id,
    required this.name,
    this.phoneNumber,
    required this.createdAt,
  });

  LendPerson copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    int? createdAt,
  }) {
    return LendPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
    };
  }

  factory LendPerson.fromMap(Map<String, dynamic> map) {
    return LendPerson(
      id: map['id'] as int?,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      createdAt: map['createdAt'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LendPerson &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LendPerson(id: $id, name: $name, phoneNumber: $phoneNumber, createdAt: $createdAt)';
}
