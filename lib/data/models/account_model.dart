class Account {
  final int? id;
  final String name; // e.g., "Nithin" or "TP"
  final String type; // e.g., "Bank" or "Cash"
  final double balance;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  // Convert Map (from SQLite) to Account object
  factory Account.fromMap(Map<String, dynamic> map) => Account(
    id: map['id'],
    name: map['name'],
    type: map['type'],
    balance: map['balance'],
  );

  // Convert Account object to Map (for SQLite)
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'balance': balance,
  };
}
