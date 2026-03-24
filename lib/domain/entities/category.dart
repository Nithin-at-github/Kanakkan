class Category {
  final int? id;
  final String name;
  final int? parentId;
  final bool isSalaryWallet;
  final int? linkedAccountId;

  const Category({
    this.id,
    required this.name,
    this.parentId,
    this.isSalaryWallet = false,
    this.linkedAccountId,
  });

  bool get isSubcategory => parentId != null;
  bool get isMainCategory => parentId == null;

  Category copyWith({
    int? id,
    String? name,
    int? parentId,
    bool clearParent = false,
    bool? isSalaryWallet,
    int? linkedAccountId,
    bool clearLinkedAccount = false,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      isSalaryWallet: isSalaryWallet ?? this.isSalaryWallet,
      linkedAccountId:
          clearLinkedAccount ? null : (linkedAccountId ?? this.linkedAccountId),
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
      'Category(id: $id, name: $name, parentId: $parentId, linkedAccountId: $linkedAccountId)';
}
