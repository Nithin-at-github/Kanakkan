class Account {
  final int? id;
  final String name;
  final String entityType; // ME / TP
  final String mediumType; // BANK / CASH

  const Account({
    this.id,
    required this.name,
    required this.entityType,
    required this.mediumType,
  });
}
