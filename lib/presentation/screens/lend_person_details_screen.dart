import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/lend_person.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/providers/lend_provider.dart';
import 'package:kanakkan/presentation/screens/add_transaction_screen.dart';
import 'package:kanakkan/presentation/screens/link_existing_transactions_screen.dart';
import 'package:kanakkan/presentation/widgets/transaction/transaction_detail_sheet.dart';
import 'package:kanakkan/presentation/widgets/animations/animated_amount.dart';
import 'package:kanakkan/presentation/widgets/animations/pressable_scale.dart';
import 'package:kanakkan/presentation/widgets/animations/staggered_entrance.dart';
import 'package:provider/provider.dart';

class LendPersonDetailsScreen extends StatefulWidget {
  final LendPerson person;

  const LendPersonDetailsScreen({super.key, required this.person});

  @override
  State<LendPersonDetailsScreen> createState() => _LendPersonDetailsScreenState();
}

class _LendPersonDetailsScreenState extends State<LendPersonDetailsScreen> {
  late LendProvider _lendProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lendProvider.setActivePersonId(widget.person.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lendProvider = Provider.of<LendProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _lendProvider.setActivePersonId(null);
    super.dispose();
  }

  Future<void> _makeCall() async {
    if (widget.person.phoneNumber == null) return;
    final url = Uri.parse('tel:${widget.person.phoneNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showSettleDialog(BuildContext context, double balance) {
    final ledger = context.read<LedgerProvider>();
    final lendProvider = context.read<LendProvider>();
    final accounts = ledger.accounts;

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Add an account first to settle transactions",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    int selectedAccountId = accounts.first.id!;
    final absoluteBalance = balance.abs();
    final isLendSettle = balance > 0; // True if they owe us, so we record an incoming repayment

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Settle Account",
                style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLendSettle
                        ? "Record a final repayment of ₹${formatAmt(absoluteBalance)} from ${widget.person.name}?"
                        : "Record a repayment of ₹${formatAmt(absoluteBalance)} to ${widget.person.name}?",
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Select Account",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedAccountId,
                        dropdownColor: AppTheme.background,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: AppTheme.onSurface),
                        style: TextStyle(color: AppTheme.onSurface, fontSize: 15),
                        items: accounts.map((acc) {
                          return DropdownMenuItem<int>(
                            value: acc.id!,
                            child: Text(acc.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedAccountId = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: AppTheme.onSurfaceVariant)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final lendCategoryId = await lendProvider.getOrCreateLendCategoryId();
                    final note = isLendSettle ? "Settle (Repayment)" : "Settle (Payment)";

                    if (isLendSettle) {
                      await ledger.addIncome(
                        amount: absoluteBalance,
                        toAccountId: selectedAccountId,
                        categoryId: lendCategoryId,
                        note: note,
                        lendPersonId: widget.person.id,
                      );
                    } else {
                      await ledger.addExpense(
                        amount: absoluteBalance,
                        fromAccountId: selectedAccountId,
                        categoryId: lendCategoryId,
                        note: note,
                        lendPersonId: widget.person.id,
                      );
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Account settled successfully",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text("Settle", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lendProvider = context.watch<LendProvider>();
    final ledger = context.watch<LedgerProvider>();
    final categories = context.watch<CategoryProvider>();

    // Resolve current balance from the people list
    final personData = lendProvider.people.firstWhere(
      (p) => p.person.id == widget.person.id,
      orElse: () => (person: widget.person, balance: 0.0),
    );
    final double balance = personData.balance;

    final transactions = lendProvider.personTransactions;

    // Outgoing = expense
    final totalOutgoing = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    // Incoming = income
    final totalIncoming = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    Color balanceColor = AppTheme.onSurfaceVariant;
    String balanceText = "Account is Settled";
    if (balance > 0) {
      balanceColor = AppTheme.success;
      balanceText = "Owes you";
    } else if (balance < 0) {
      balanceColor = AppTheme.error;
      balanceText = "You owe";
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
        title: const Text(
          "Contact Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link, color: Colors.white),
            tooltip: "Link existing transactions",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LinkExistingTransactionsScreen(person: widget.person),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // CONTACT HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            color: AppTheme.primary,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                  child: Text(
                    widget.person.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.person.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.person.phoneNumber != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _makeCall,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 14, color: AppTheme.accent),
                        const SizedBox(width: 6),
                        Text(
                          widget.person.phoneNumber!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // Balance summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          balanceText,
                          style: TextStyle(fontSize: 12, color: balanceColor),
                        ),
                        const SizedBox(height: 4),
                        AnimatedAmount(
                          amount: balance.abs(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: balanceColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "LENDED",
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        AnimatedAmount(
                          amount: totalOutgoing,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "RETURNED",
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        AnimatedAmount(
                          amount: totalIncoming,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TRANSACTION HISTORY TITLE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Transaction History",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
          ),

          // TRANSACTION LIST
          Expanded(
            child: lendProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                    ? _emptyHistory()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isIncome = tx.type == "income";
                          final accountName = ledger.resolvePrimaryAccountName(tx);
                          final categoryName = categories.resolveTransactionCategoryName(tx);
                          final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);

                          return StaggeredEntrance(
                            index: index,
                            child: Card(
                              color: AppTheme.surface,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.divider),
                              ),
                              child: ListTile(
                                onTap: () => TransactionDetailSheet.show(context, tx: tx),
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: (isIncome ? AppTheme.success : AppTheme.error)
                                      .withValues(alpha: 0.1),
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isIncome ? AppTheme.success : AppTheme.error,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  tx.note != null && tx.note!.isNotEmpty
                                      ? tx.note!
                                      : categoryName,
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
                                trailing: Text(
                                  "₹${formatAmt(tx.amount)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isIncome ? AppTheme.success : AppTheme.error,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // ACTIONS ROW AT THE BOTTOM
          Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (balance != 0) ...[
                  PressableScale(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.handshake_outlined),
                        label: const Text(
                          "Settle Account",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          side: BorderSide(color: AppTheme.accent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showSettleDialog(context, balance),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: PressableScale(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text(
                            "Lend Money",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTransactionScreen(
                                preselectedLendPersonId: widget.person.id,
                                initialType: TransactionType.expense,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PressableScale(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text(
                            "Record Return",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: AppTheme.background,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTransactionScreen(
                                preselectedLendPersonId: widget.person.id,
                                initialType: TransactionType.income,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            "No lend history yet",
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
