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
}
