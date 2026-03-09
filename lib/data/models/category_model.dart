import 'package:kanakkan/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    super.id,
    required super.name,
    required super.type,
    super.parentId,
    super.isSalaryWallet = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'parentId': parentId,
      // isSalaryWallet is intentionally excluded from INSERT/UPDATE here.
      // It is managed exclusively via CategoryRepository.setSalaryWallet()
      // and cleared via clearSalaryWallet(). The DB DEFAULT 0 handles new rows.
    };
  }

  static CategoryModel fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      parentId: map['parentId'] as int?,
      isSalaryWallet: (map['isSalaryWallet'] as int? ?? 0) == 1,
    );
  }
}
