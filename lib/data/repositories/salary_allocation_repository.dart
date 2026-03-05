import 'package:kanakkan/data/database/database_helper.dart';

class SalaryAllocationRepository {
  final dbHelper = DatabaseHelper.instance;

  /// ---------- TEMPLATE ----------

  Future<List<Map<String, dynamic>>> getTemplate() async {
    final db = await dbHelper.database;
    return db.query("salary_allocation_templates");
  }

  Future<void> saveTemplate(Map<int, double> template) async {
    final db = await dbHelper.database;

    await db.delete("salary_allocation_templates");

    for (final entry in template.entries) {
      await db.insert("salary_allocation_templates", {
        "categoryId": entry.key,
        "amount": entry.value,
      });
    }
  }

  /// ---------- ACTUAL ALLOCATIONS ----------

  Future<void> insertAllocation({
    required int salaryTransactionId,
    required int categoryId,
    required double amount,
  }) async {
    final db = await dbHelper.database;

    await db.insert("salary_allocations", {
      "salaryTransactionId": salaryTransactionId,
      "categoryId": categoryId,
      "amount": amount,
    });
  }

  Future<List<Map<String, dynamic>>> getAllocations(
    int salaryTransactionId,
  ) async {
    final db = await dbHelper.database;

    return db.query(
      "salary_allocations",
      where: "salaryTransactionId=?",
      whereArgs: [salaryTransactionId],
    );
  }

  Future<void> deleteAllocations(int salaryTransactionId) async {
    final db = await dbHelper.database;

    await db.delete(
      "salary_allocations",
      where: "salaryTransactionId=?",
      whereArgs: [salaryTransactionId],
    );
  }
}
