import 'package:flutter/material.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      context.read<LedgerProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final transactions = provider.transactions;
    final grouped = _groupByDate(transactions);

    return Scaffold(
      appBar: AppBar(title: const Text("Transactions")),
      body: Column(
        children: [
          /// FILTERS
          _buildFilters(context),

          const Divider(height: 1),

          /// LIST
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text("No transactions yet"))
                : ListView(
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dateHeader(entry.key),

                          ...entry.value.map((tx) {
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: _transactionTile(tx),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  /// FILTER CHIPS
  Widget _buildFilters(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _filterChip(context, "All", null),
          _filterChip(context, "Income", "income"),
          _filterChip(context, "Expense", "expense"),
          _filterChip(context, "Transfer", "transfer"),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, String? type) {
    final provider = context.watch<LedgerProvider>();

    return ChoiceChip(
      label: Text(label),
      selected: provider.currentFilter == type,
      onSelected: (_) {
        provider.loadTransactions(type: type);
      },
    );
  }

  /// DATE GROUPING
  Map<String, List<TransactionEntity>> _groupByDate(
    List<TransactionEntity> transactions,
  ) {
    final Map<String, List<TransactionEntity>> grouped = {};

    for (var tx in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);

      final key = "${date.day}/${date.month}/${date.year}";

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(tx);
    }

    return grouped;
  }

  /// DATE HEADER
  Widget _dateHeader(String date) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        date,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  /// LEDGER TILE
  Widget _transactionTile(TransactionEntity tx) {
    final isIncome = tx.type == "income";
    final isExpense = tx.type == "expense";
    final isTransfer = tx.type == "transfer";

    IconData icon;
    Color color;
    String prefix = "";

    if (isIncome) {
      icon = Icons.arrow_downward;
      color = Colors.green;
      prefix = "+";
    } else if (isExpense) {
      icon = Icons.arrow_upward;
      color = Colors.red;
      prefix = "-";
    } else {
      icon = Icons.swap_horiz;
      color = Colors.blueGrey;
      prefix = "";
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        tx.type.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${tx.fromAccountId ?? '-'} → ${tx.toAccountId ?? '-'}",
            style: const TextStyle(fontSize: 12),
          ),

          if (tx.note != null && tx.note!.isNotEmpty) Text(tx.note!),
        ],
      ),
      trailing: Text(
        "$prefix ₹${tx.amount.toStringAsFixed(2)}",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 16,
        ),
      ),
    );
  }
}
