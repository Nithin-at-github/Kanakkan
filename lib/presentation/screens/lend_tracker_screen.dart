import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/core/widgets/confirm_delete_dialog.dart';
import 'package:kanakkan/domain/entities/lend_person.dart';
import 'package:kanakkan/presentation/dialogs/quick_add_lend_person_dialog.dart';
import 'package:kanakkan/presentation/providers/lend_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/screens/lend_person_details_screen.dart';
import 'package:kanakkan/presentation/widgets/animations/animated_amount.dart';
import 'package:kanakkan/presentation/widgets/animations/pressable_scale.dart';
import 'package:kanakkan/presentation/widgets/animations/staggered_entrance.dart';
import 'package:provider/provider.dart';

enum LendFilterMode { all, active, settled }

class LendTrackerScreen extends StatefulWidget {
  const LendTrackerScreen({super.key});

  @override
  State<LendTrackerScreen> createState() => _LendTrackerScreenState();
}

class _LendTrackerScreenState extends State<LendTrackerScreen> {
  LendFilterMode _filter = LendFilterMode.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LendProvider>().loadPeople();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lendProvider = context.watch<LendProvider>();
    final people = lendProvider.people;

    final ledger = context.watch<LedgerProvider>();

    // Computed totals (all-time stats for lended & borrowed)
    final double totalLended = ledger.transactions
        .where((t) => t.lendPersonId != null && t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final double totalBorrowed = ledger.transactions
        .where((t) => t.lendPersonId != null && t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final double netBalance = totalLended - totalBorrowed;

    // Filter people
    final filteredPeople = people.where((p) {
      switch (_filter) {
        case LendFilterMode.active:
          return p.balance != 0;
        case LendFilterMode.settled:
          return p.balance == 0;
        case LendFilterMode.all:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: PressableScale(
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.accent,
          elevation: 6,
          icon: Icon(Icons.add, color: AppTheme.primary),
          label: Text(
            "Add Contact",
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () => QuickAddLendPersonDialog.show(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // TOP HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Lends & Borrows",
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Net Balance → ",
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AnimatedAmount(
                        amount: netBalance,
                        style: TextStyle(
                          color: netBalance > 0
                              ? AppTheme.success
                              : netBalance < 0
                                  ? AppTheme.error
                                  : AppTheme.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryColumn(
                        "LENDED",
                        totalLended,
                        AppTheme.success,
                      ),
                      _summaryColumn(
                        "RETURNS",
                        totalBorrowed,
                        AppTheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FILTER CHIPS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip("All", LendFilterMode.all),
                const SizedBox(width: 8),
                _buildFilterChip("Active", LendFilterMode.active),
                const SizedBox(width: 8),
                _buildFilterChip("Settled", LendFilterMode.settled),
              ],
            ),

            const SizedBox(height: 14),

            // CONTACTS LIST CONTAINER
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filteredPeople.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          _emptyMessage(),
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPeople.length,
                      itemBuilder: (context, index) {
                        final item = filteredPeople[index];
                        return StaggeredEntrance(
                          index: index,
                          child: _personTile(context, item.person, item.balance),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, LendFilterMode mode) {
    final isSelected = _filter == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = mode),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.onSurface.withValues(alpha: 0.04),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.divider,
        ),
      ),
      showCheckmark: false,
    );
  }

  String _emptyMessage() {
    switch (_filter) {
      case LendFilterMode.active:
        return "No active lends or borrows";
      case LendFilterMode.settled:
        return "No settled lend accounts";
      case LendFilterMode.all:
        return "No contacts added yet";
    }
  }

  Widget _personTile(BuildContext context, LendPerson person, double balance) {
    final lendProvider = context.read<LendProvider>();

    Color balanceColor = AppTheme.onSurfaceVariant;
    String balanceText = "Settled";
    if (balance > 0) {
      balanceColor = AppTheme.success;
      balanceText = "Owes you";
    } else if (balance < 0) {
      balanceColor = AppTheme.error;
      balanceText = "You owe";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: .15)),
        color: AppTheme.surface,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LendPersonDetailsScreen(person: person),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Initials Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
              child: Text(
                person.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Person Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  if (person.phoneNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      person.phoneNumber!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Balance info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balanceText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: balanceColor,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedAmount(
                  amount: balance.abs(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Options menu
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: Icon(Icons.more_vert, color: AppTheme.onSurface, size: 20),
              onSelected: (value) async {
                if (value == "edit") {
                  QuickAddLendPersonDialog.show(context, person: person);
                } else if (value == "delete") {
                  final confirm = await ConfirmDeleteDialog.show(
                    context: context,
                    title: "Delete Contact",
                    message: "All related transactions will remain but the contact link will be removed.",
                  );
                  if (!confirm) return;
                  await lendProvider.deletePerson(person.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "Contact deleted",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: "edit",
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text("Edit"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Text("Delete", style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryColumn(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        AnimatedAmount(
          amount: amount,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
