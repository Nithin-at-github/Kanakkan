import 'package:kanakkan/domain/entities/category_balance_entity.dart';

class CategoryBalanceModel extends CategoryBalance {
  CategoryBalanceModel({required super.categoryId, required super.balance});

  Map<String, dynamic> toMap() => {
    "categoryId": categoryId,
    "balance": balance,
  };

  factory CategoryBalanceModel.fromMap(Map<String, dynamic> map) {
    return CategoryBalanceModel(
      categoryId: map["categoryId"],
      balance: (map["balance"] as num).toDouble(),
    );
  }
}
