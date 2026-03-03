import 'package:kanakkan/domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    super.id,
    required super.name,
    required double initialBalance,
  }) : super(initialBalance: initialBalance);

  /// Convert DB map → Model
  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'],
      name: map['name'],
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert Model → DB map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initialBalance': initialBalance,
    };
  }
}
