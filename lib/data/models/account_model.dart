import 'package:kanakkan/domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    super.id,
    required super.name,
    required super.entityType,
    required super.mediumType,
  });

  /// Convert DB map → Model
  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'],
      name: map['name'],
      entityType: map['entityType'],
      mediumType: map['mediumType'],
    );
  }

  /// Convert Model → DB map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'entityType': entityType,
      'mediumType': mediumType,
    };
  }
}
