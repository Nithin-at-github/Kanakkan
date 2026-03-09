String? validateSubcategoryName(String name) {
  final trimmed = name.trim();

  if (trimmed.isEmpty) {
    return "Name cannot be empty";
  }

  if (trimmed.length < 2) {
    return "Must be at least 2 characters";
  }

  if (trimmed.length > 30) {
    return "Must be under 30 characters";
  }

  return null;
}
