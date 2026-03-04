class FormValidation {
  /// ================= TEXT =================

  static String? requiredText(String value, {String field = "Field"}) {
    if (value.trim().isEmpty) {
      return "$field is required";
    }
    return null;
  }

  static String? minLength(String value, int length, {String field = "Field"}) {
    if (value.trim().length < length) {
      return "$field must be at least $length characters";
    }
    return null;
  }

  static String? maxLength(String value, int length, {String field = "Field"}) {
    if (value.trim().length > length) {
      return "$field must be under $length characters";
    }
    return null;
  }

  /// ================= NUMBER =================

  static String? validNumber(String value, {String field = "Value"}) {
    if (value.trim().isEmpty) return null;

    final number = double.tryParse(value);

    if (number == null) {
      return "$field must be a valid number";
    }

    return null;
  }

  static String? positiveNumber(String value, {String field = "Value"}) {
    final number = double.tryParse(value);

    if (number == null) {
      return "$field must be a valid number";
    }

    if (number < 0) {
      return "$field cannot be negative";
    }

    return null;
  }

  /// ================= COMBINED HELPERS =================

  static String? accountName(String value) {
    return requiredText(value, field: "Account name") ??
        minLength(value, 2, field: "Account name") ??
        maxLength(value, 40, field: "Account name");
  }

  static String? categoryName(String value) {
    return requiredText(value, field: "Category name") ??
        minLength(value, 2, field: "Category name") ??
        maxLength(value, 40, field: "Category name");
  }

  static String? balance(String value) {
    return validNumber(value, field: "Balance") ??
        positiveNumber(value, field: "Balance");
  }

  static String? budget(String value) {
    if (value.trim().isEmpty) {
      return "Budget amount required";
    }

    final amount = double.tryParse(value);

    if (amount == null) {
      return "Invalid amount";
    }

    if (amount <= 0) {
      return "Budget must be greater than 0";
    }

    if (amount > 100000000) {
      return "Budget too large";
    }

    return null;
  }
}
