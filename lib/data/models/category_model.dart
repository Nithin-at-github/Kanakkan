import 'package:kanakkan/domain/entities/category.dart';

class CategoryModel extends Category {
  CategoryModel({super.id, required super.name, required super.type, required super.parentId});

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'parentId': parentId,
    };
  }

  static CategoryModel fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      parentId: map['parentId'] as int?,
    );
  }
}
