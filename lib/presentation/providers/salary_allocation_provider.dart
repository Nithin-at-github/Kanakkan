import 'package:flutter/material.dart';
import 'package:kanakkan/data/repositories/salary_allocation_repository.dart';

class SalaryAllocationProvider extends ChangeNotifier {
  final SalaryAllocationRepository _repository = SalaryAllocationRepository();

  Map<int, double> template = {};

  Future<void> loadTemplate() async {
    final data = await _repository.getTemplate();

    template.clear();

    for (final row in data) {
      template[row["categoryId"]] = (row["amount"] as num).toDouble();
    }
    
    notifyListeners();
  }

  Future<void> saveTemplate(Map<int, double> allocations) async {
    await _repository.saveTemplate(allocations);

    template = allocations;

    notifyListeners();
  }
}
