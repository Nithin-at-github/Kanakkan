import 'package:kanakkan/domain/entities/category.dart';

class CategoryModel extends Category {
  CategoryModel({super.id, required super.name, required super.type});

  Map<String, dynamic> toMap() {
    return {"id": id, "name": name, "type": type};
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(id: map["id"], name: map["name"], type: map["type"]);
  }
}
