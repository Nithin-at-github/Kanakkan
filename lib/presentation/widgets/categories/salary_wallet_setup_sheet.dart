import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

/// Reusable bottom sheet for explaining and designating the salary wallet.
/// Opens from the app bar crown button and from the amber banner.
class SalaryWalletSetupSheet extends StatelessWidget {
  const SalaryWalletSetupSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SalaryWalletSetupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final ledger = context.watch<LedgerProvider>();
    final allCategories = provider.mainCategories;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── DRAG HANDLE ──
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // ── HEADER ──
                    const Text(
                      '👑',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Salary Wallet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── EXPLANATION CARD ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FeatureRow(
                            icon: Icons.account_balance_wallet,
                            title: 'What is the Salary Wallet?',
                            body:
                                'One income category acts as your main salary source. When you receive income into it, you can distribute it across your expense wallets automatically.',
                          ),
                          SizedBox(height: 14),
                          _FeatureRow(
                            icon: Icons.call_split,
                            title: 'Automatic Distribution',
                            body:
                                'After adding salary income, a dialog lets you split it — e.g. ₹5000 to Food, ₹8000 to Rent — funding each wallet for the month.',
                          ),
                          SizedBox(height: 14),
                          _FeatureRow(
                            icon: Icons.safety_check,
                            title: 'Expense Safety Net',
                            body:
                                'If an expense exceeds a wallet\'s balance, it automatically pulls the shortfall from your salary wallet so nothing fails.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── PICK CATEGORY ──
                    if (allCategories.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No categories yet. Add one first from the Categories screen.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        provider.hasSalaryWallet
                            ? 'Current Salary Wallet'
                            : 'Choose a Category',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.hasSalaryWallet
                            ? 'Tap another to switch, or remove the current one.'
                            : 'This category will receive your salary and fund your wallets.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...allCategories.map(
                        (cat) => _CategoryPickerTile(
                          category: cat,
                          isSelected: cat.isSalaryWallet,
                          onTap: () async {
                            if (!context.mounted) return;
                            final confirmed = await confirmWalletChange(
                              context: context,
                              categoryProvider: provider,
                              ledgerProvider: ledger,
                              tappedCategory: cat,
                            );

                            if (!context.mounted) return;
                            if (confirmed) {
                              if (cat.isSalaryWallet) {
                                await provider.clearSalaryWallet();
                              } else {
                                await provider.setSalaryWallet(cat.id!);
                              }
                            }
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── CLOSE ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: AppTheme.accent.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRMATION HELPER
// ─────────────────────────────────────────────────────────────────────────────

Future<bool> confirmWalletChange({
  required BuildContext context,
  required CategoryProvider categoryProvider,
  required LedgerProvider ledgerProvider,
  required Category tappedCategory,
}) async {
  // --- UNUSUAL CHOICE CHECK ---
  // If the category being set as salary wallet already has expense transactions,
  // we show a warning (but only if it's not already the salary wallet).
  final hasExpenseTx = ledgerProvider.transactions.any(
    (tx) => tx.categoryId == tappedCategory.id && tx.type == 'expense',
  );

  if (hasExpenseTx && !tappedCategory.isSalaryWallet) {
    if (!context.mounted) return false;
    final proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Unusual Choice',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            content: Text(
              '"${tappedCategory.name}" already has expense transactions. Designating it as the salary wallet is unusual but allowed. Proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Proceed',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!proceed) return false;
  }

  final current = categoryProvider.salaryWalletCategory;

  // Case 1: tapping the currently active wallet → removing it
  if (tappedCategory.isSalaryWallet) {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _WalletChangeDialog(
            title: 'Remove Salary Wallet?',
            icon: Icons.workspace_premium_outlined,
            iconColor: Colors.orange,
            points: const [
              _ChangePoint(
                icon: Icons.block,
                color: Colors.orange,
                text:
                    'Salary distribution dialog will no longer appear when you add income.',
              ),
              _ChangePoint(
                icon: Icons.safety_check_outlined,
                color: Colors.orange,
                text:
                    'Expense safety net (auto salary fallback) will be disabled.',
              ),
              _ChangePoint(
                icon: Icons.history,
                color: Colors.green,
                text: 'Past transactions and wallet balances are unaffected.',
              ),
            ],
            confirmLabel: 'Remove',
            confirmColor: Colors.orange,
          ),
        ) ??
        false;
  }

  // Case 2: switching from one wallet to another
  if (current != null) {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _WalletChangeDialog(
            title: 'Switch Salary Wallet?',
            icon: Icons.swap_horiz,
            iconColor: AppTheme.accent,
            points: [
              _ChangePoint(
                icon: Icons.workspace_premium,
                color: Colors.amber,
                text:
                    '"${tappedCategory.name}" will become the new salary wallet.',
              ),
              _ChangePoint(
                icon: Icons.workspace_premium_outlined,
                color: Colors.black45,
                text: '"${current.name}" will no longer receive distribution.',
              ),
              _ChangePoint(
                icon: Icons.call_split,
                color: AppTheme.accent,
                text:
                    'Future income added to "${tappedCategory.name}" will trigger wallet distribution.',
              ),
              const _ChangePoint(
                icon: Icons.history,
                color: Colors.green,
                text:
                    'Past salary transactions and stored splits are unaffected.',
              ),
            ],
            confirmLabel: 'Switch',
            confirmColor: AppTheme.accent,
          ),
        ) ??
        false;
  }

  // Case 3: no current wallet → designating for the first time, no confirmation needed
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY PICKER TILE
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPickerTile extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPickerTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.black12,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ]
              : const [BoxShadow(blurRadius: 4, color: Colors.black12)],
        ),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected
                  ? Colors.amber.withValues(alpha: 0.2)
                  : AppTheme.success.withValues(alpha: 0.1),
              child: Icon(
                Icons.arrow_downward,
                color: isSelected ? Colors.amber : AppTheme.success,
                size: 16,
              ),
            ),
            const SizedBox(width: 14),

            // Name
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isSelected ? Colors.amber.shade800 : Colors.black87,
                ),
              ),
            ),

            // Check / crown
            if (isSelected)
              const Icon(Icons.workspace_premium, color: Colors.amber, size: 22)
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: Colors.black26,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WALLET CHANGE CONFIRMATION DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePoint {
  final IconData icon;
  final Color color;
  final String text;
  const _ChangePoint({
    required this.icon,
    required this.color,
    required this.text,
  });
}

class _WalletChangeDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_ChangePoint> points;
  final String confirmLabel;
  final Color confirmColor;

  const _WalletChangeDialog({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.points,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── ICON ──
            CircleAvatar(
              radius: 28,
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),

            // ── TITLE ──
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Here's what will change:",
              style: TextStyle(fontSize: 13, color: Colors.black45),
            ),
            const SizedBox(height: 16),

            // ── CHANGE POINTS ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: points.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(p.icon, color: p.color, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── ACTIONS ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE ROW
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.amber, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
