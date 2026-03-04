class Account {
  final int? id;
  final String name;
  /// starting money in the account when it is created
  final double initialBalance;

  const Account({
    this.id,
    required this.name,
    required this.initialBalance,
  });

  Account copyWith({int? id, String? name, double? initialBalance}) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }
}
