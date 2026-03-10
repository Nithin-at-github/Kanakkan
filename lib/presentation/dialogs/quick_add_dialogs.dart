import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ADD ACCOUNT
// Full account form (name + initial balance) shown as a dialog
// Returns the newly created Account or null if cancelled
// ─────────────────────────────────────────────────────────────────────────────

class QuickAddAccountDialog extends StatefulWidget {
  const QuickAddAccountDialog({super.key});

  static Future<Account?> show(BuildContext context) {
    return showDialog<Account?>(
      context: context,
      builder: (_) => const QuickAddAccountDialog(),
    );
  }

  @override
  State<QuickAddAccountDialog> createState() => _QuickAddAccountDialogState();
}

class _QuickAddAccountDialogState extends State<QuickAddAccountDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String? _nameError;
  String? _balanceError;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  bool _validate() {
    String? nameErr;
    String? balErr;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      nameErr = "Account name is required";
    } else if (name.length < 2) {
      nameErr = "Name must be at least 2 characters";
    } else if (name.length > 40) {
      nameErr = "Name must be under 40 characters";
    }

    final balText = _balanceController.text.trim();
    if (balText.isNotEmpty) {
      final val = double.tryParse(balText);
      if (val == null) {
        balErr = "Enter a valid number";
      } else if (val < 0) {
        balErr = "Balance cannot be negative";
      }
    }

    setState(() {
      _nameError = nameErr;
      _balanceError = balErr;
    });

    return nameErr == null && balErr == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _saving = true);

    final ledger = context.read<LedgerProvider>();
    ledger.clearError();

    final initialBalance = double.tryParse(_balanceController.text.trim()) ?? 0;

    await ledger.addAccount(
      Account(
        name: _nameController.text.trim(),
        initialBalance: initialBalance,
      ),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ledger.lastError != null) {
      setState(() => _nameError = ledger.lastError);
      return;
    }

    // Return the newly created account
    final created = ledger.accounts.firstWhere(
      (a) => a.name == _nameController.text.trim(),
    );
    if (mounted) Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Account",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
        
              // Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Account name",
                  filled: true,
                  fillColor: Colors.white,
                  errorText: _nameError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() => _nameError = null),
              ),
              const SizedBox(height: 14),
        
              // Initial balance
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Initial balance (optional)",
                  prefixText: "₹ ",
                  filled: true,
                  fillColor: Colors.white,
                  errorText: _balanceError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() => _balanceError = null),
              ),
              const SizedBox(height: 24),
        
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ADD CATEGORY
// Step 1: pick type (income/expense) + enter name → creates main category
// Step 2 (optional): pick parent → enter subcategory name
// Returns newly created Category or null
// ─────────────────────────────────────────────────────────────────────────────

class QuickAddCategoryDialog extends StatefulWidget {
  /// Pre-fill the type if known from context (income/expense screen)
  final String? preselectedType;

  const QuickAddCategoryDialog({super.key, this.preselectedType});

  static Future<Category?> show(
    BuildContext context, {
    String? preselectedType,
  }) {
    return showDialog<Category?>(
      context: context,
      builder: (_) => QuickAddCategoryDialog(preselectedType: preselectedType),
    );
  }

  @override
  State<QuickAddCategoryDialog> createState() => _QuickAddCategoryDialogState();
}

class _QuickAddCategoryDialogState extends State<QuickAddCategoryDialog> {
  final _nameController = TextEditingController();
  String? _selectedType;
  // null = adding main category, non-null = adding subcategory under this parent
  Category? _selectedParent;
  bool _isSubcategoryMode = false;
  String? _nameError;
  String? _typeError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _validate() {
    String? nameErr;
    String? typeErr;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      nameErr = "Name is required";
    } else if (name.length < 2) {
      nameErr = "Name must be at least 2 characters";
    } else if (name.length > 30) {
      nameErr = "Name must be under 30 characters";
    }

    if (!_isSubcategoryMode && _selectedType == null) {
      typeErr = "Select a type";
    }

    if (_isSubcategoryMode && _selectedParent == null) {
      typeErr = "Select a parent category";
    }

    setState(() {
      _nameError = nameErr;
      _typeError = typeErr;
    });

    return nameErr == null && typeErr == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);

    final provider = context.read<CategoryProvider>();
    provider.clearError();

    if (_isSubcategoryMode) {
      await provider.addSubcategory(
        name: _nameController.text.trim(),
        parentId: _selectedParent!.id!,
      );
    } else {
      await provider.addCategory(
        Category(name: _nameController.text.trim(), type: _selectedType!),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (provider.lastError != null) {
      setState(() => _nameError = provider.lastError);
      return;
    }

    // Return the created category
    final name = _nameController.text.trim();
    final created = provider.categories.firstWhere((c) => c.name == name);
    if (mounted) Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add Category",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
        
              // ── MODE TOGGLE ──
              Row(
                children: [
                  _ModeChip(
                    label: "Main Category",
                    selected: !_isSubcategoryMode,
                    onTap: () => setState(() {
                      _isSubcategoryMode = false;
                      _selectedParent = null;
                      _typeError = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    label: "Subcategory",
                    selected: _isSubcategoryMode,
                    onTap: () => setState(() {
                      _isSubcategoryMode = true;
                      _selectedParent = null;
                      _typeError = null;
                    }),
                  ),
                ],
              ),
        
              const SizedBox(height: 16),
        
              // ── TYPE SELECTOR (main category only) ──
              if (!_isSubcategoryMode) ...[
                Row(
                  children: [
                    _TypeChip(
                      label: "Expense",
                      color: AppTheme.error,
                      selected: _selectedType == "expense",
                      onTap: () => setState(() {
                        _selectedType = "expense";
                        _typeError = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: "Income",
                      color: AppTheme.success,
                      selected: _selectedType == "income",
                      onTap: () => setState(() {
                        _selectedType = "income";
                        _typeError = null;
                      }),
                    ),
                  ],
                ),
                if (_typeError != null && !_isSubcategoryMode) ...[
                  const SizedBox(height: 6),
                  Text(
                    _typeError!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),
              ],
        
              // ── PARENT PICKER (subcategory only) ──
              if (_isSubcategoryMode) ...[
                Builder(
                  builder: (context) {
                    // Always recompute from provider so list is fresh after quick-add
                    final allMains = context
                        .read<CategoryProvider>()
                        .mainCategories;
                    // Validate: if _selectedParent no longer in list, reset it
                    final parentInList =
                        _selectedParent == null ||
                        allMains.any((c) => c.id == _selectedParent!.id);
                    if (!parentInList) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => setState(() => _selectedParent = null),
                      );
                    }
                    return DropdownButtonFormField<Category>(
                      initialValue: parentInList ? _selectedParent : null,
                      decoration: InputDecoration(
                        labelText: "Parent category",
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _typeError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: allMains
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(
                                    c.type == "income"
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    size: 14,
                                    color: c.type == "income"
                                        ? AppTheme.success
                                        : AppTheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() {
                        _selectedParent = val;
                        _selectedType = val?.type;
                        _typeError = null;
                      }),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],
        
              // ── NAME FIELD ──
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _isSubcategoryMode
                      ? "Subcategory name"
                      : "Category name",
                  filled: true,
                  fillColor: Colors.white,
                  errorText: _nameError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() => _nameError = null),
              ),
        
              const SizedBox(height: 24),
        
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SHARED CHIP WIDGETS
// ─────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.black26,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.black26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
