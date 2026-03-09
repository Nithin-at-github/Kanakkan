class Category {
  final int? id;
  final String name;
  final String type;
  final int? parentId;

  const Category({
    this.id,
    required this.name,
    required this.type,
    this.parentId,
  });

  bool get isSubcategory => parentId != null;
  bool get isMainCategory => parentId == null;

  Category copyWith({
    int? id,
    String? name,
    String? type,
    int? parentId,
    bool clearParent = false,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: clearParent ? null : (parentId ?? this.parentId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Category(id: $id, name: $name, type: $type, parentId: $parentId)';
}
