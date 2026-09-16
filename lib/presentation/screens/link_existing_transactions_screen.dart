import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/lend_person.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/providers/lend_provider.dart';
import 'package:kanakkan/presentation/widgets/animations/staggered_entrance.dart';
import 'package:provider/provider.dart';

class LinkExistingTransactionsScreen extends StatefulWidget {
  final LendPerson person;

  const LinkExistingTransactionsScreen({super.key, required this.person});

  @override
  State<LinkExistingTransactionsScreen> createState() => _LinkExistingTransactionsScreenState();
}

class _LinkExistingTransactionsScreenState extends State<LinkExistingTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedTxIds = {};
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();
    final categories = context.watch<CategoryProvider>();
    final lendProvider = context.watch<LendProvider>();

    // 1. Get all unlinked non-transfer transactions
    final unlinkedTxs = ledger.transactions
        .where((t) => t.lendPersonId == null && t.transferGroupId == null)
        .toList();

    // Get unique active categories in unlinked transactions
    final uniqueCategoryIds = unlinkedTxs.map((t) => t.categoryId).toSet();
    final activeCategories = uniqueCategoryIds
        .map((id) => categories.resolveCategory(id))
        .whereType<Category>()
        .toList();
    activeCategories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // 2. Apply category filter
    final categoryFilteredTxs = unlinkedTxs.where((tx) {
      if (_selectedCategoryId == null) return true;

      final txCat = categories.resolveCategory(tx.categoryId);
      if (txCat == null) return false;

      // If we filtered by subcategory
      if (txCat.id == _selectedCategoryId) return true;

      // If we filtered by parent category
      if (txCat.parentId == _selectedCategoryId) return true;

      return false;
    }).toList();

    // 3. Apply search filter
    final filteredTxs = categoryFilteredTxs.where((tx) {
      if (_searchQuery.isEmpty) return true;

      final query = _searchQuery.toLowerCase();
      final note = tx.note?.toLowerCase() ?? '';
      final categoryName = categories.resolveTransactionCategoryName(tx).toLowerCase();
      final accountName = ledger.resolvePrimaryAccountName(tx).toLowerCase();
      final amountStr = tx.amount.toString();

      return note.contains(query) ||
          categoryName.contains(query) ||
          accountName.contains(query) ||
          amountStr.contains(query);
    }).toList();

    // 3. Separate into Suggested and Others
    final personName = widget.person.name.toLowerCase();
    final suggestedTxs = <TransactionEntity>[];
    final otherTxs = <TransactionEntity>[];

    for (final tx in filteredTxs) {
      final categoryName = categories.resolveTransactionCategoryName(tx).toLowerCase();
      final note = tx.note?.toLowerCase() ?? '';

      if (categoryName.contains('lend') || note.contains(personName)) {
        suggestedTxs.add(tx);
      } else {
        otherTxs.add(tx);
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Link Transactions",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Select records to link to ${widget.person.name}",
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _selectedCategoryId != null ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _selectedCategoryId != null ? AppTheme.accent : Colors.white,
            ),
            tooltip: "Filter by category",
            onPressed: () => _showCategoryFilterDialog(context, activeCategories),
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primary,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by note, category, account or amount...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.5)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white10,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // SELECT ALL PANEL
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${filteredTxs.length} transaction${filteredTxs.length == 1 ? '' : 's'} found",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (filteredTxs.isNotEmpty)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      final allFilteredIds = filteredTxs.map((t) => t.id!).toSet();
                      final allSelected = allFilteredIds.every((id) => _selectedTxIds.contains(id));

                      setState(() {
                        if (allSelected) {
                          _selectedTxIds.removeAll(allFilteredIds);
                        } else {
                          _selectedTxIds.addAll(allFilteredIds);
                        }
                      });
                    },
                    child: Text(
                      filteredTxs.map((t) => t.id!).every((id) => _selectedTxIds.contains(id))
                          ? "Deselect All"
                          : "Select All",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          // LIST OF TRANSACTIONS
          Expanded(
            child: unlinkedTxs.isEmpty
                ? _emptyState("No unlinked transactions available")
                : filteredTxs.isEmpty
                    ? _emptyState("No matches found for '$_searchQuery'")
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        children: [
                          if (suggestedTxs.isNotEmpty) ...[
                            _sectionHeader("SUGGESTED FOR ${widget.person.name.toUpperCase()}", Icons.star),
                            ...suggestedTxs.asMap().entries.map((entry) {
                              return StaggeredEntrance(
                                index: entry.key,
                                child: _txListTile(entry.value, categories, ledger, isSuggested: true),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                          if (otherTxs.isNotEmpty) ...[
                            _sectionHeader("OTHER TRANSACTIONS", Icons.list),
                            ...otherTxs.asMap().entries.map((entry) {
                              return StaggeredEntrance(
                                index: entry.key + suggestedTxs.length,
                                child: _txListTile(entry.value, categories, ledger),
                              );
                            }),
                          ],
                        ],
                      ),
          ),
        ],
      ),
      bottomSheet: _selectedTxIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.link),
                  label: Text(
                    "Link ${_selectedTxIds.length} Selected Transaction${_selectedTxIds.length > 1 ? 's' : ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await lendProvider.linkTransactions(widget.person.id!, _selectedTxIds.toList());
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Successfully linked ${_selectedTxIds.length} records",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            )
          : null,
    );
  }

  void _showCategoryFilterDialog(BuildContext context, List<Category> activeCategories) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.dialogSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Filter by Category",
            style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: activeCategories.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final Category? cat = isAll ? null : activeCategories[index - 1];
                final isSelected = isAll
                    ? _selectedCategoryId == null
                    : _selectedCategoryId == cat!.id;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    isAll ? "All Categories" : cat!.name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.accent : AppTheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppTheme.accent, size: 20)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = isAll ? null : cat!.id;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: AppTheme.onSurfaceVariant)),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _txListTile(
    TransactionEntity tx,
    CategoryProvider categories,
    LedgerProvider ledger, {
    bool isSuggested = false,
  }) {
    final isIncome = tx.type == "income";
    final accountName = ledger.resolvePrimaryAccountName(tx);
    final categoryName = categories.resolveTransactionCategoryName(tx);
    final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
    final isChecked = _selectedTxIds.contains(tx.id!);

    return Card(
      color: isChecked ? AppTheme.accent.withValues(alpha: 0.05) : AppTheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isChecked ? AppTheme.accent : AppTheme.divider,
          width: isChecked ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isChecked,
        activeColor: AppTheme.accent,
        checkColor: AppTheme.primary,
        onChanged: (val) {
          setState(() {
            if (val == true) {
              _selectedTxIds.add(tx.id!);
            } else {
              _selectedTxIds.remove(tx.id!);
            }
          });
        },
        secondary: CircleAvatar(
          radius: 18,
          backgroundColor: (isIncome ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? AppTheme.success : AppTheme.error,
            size: 16,
          ),
        ),
        title: Text(
          tx.note != null && tx.note!.isNotEmpty ? tx.note! : categoryName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          "$accountName • ${DateFormat("MMM d, yyyy").format(date)}",
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
