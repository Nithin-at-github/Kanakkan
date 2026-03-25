import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/widgets/categories/category_tile.dart';
import 'package:kanakkan/presentation/widgets/categories/salary_wallet_setup_sheet.dart';

class CategorySection extends StatelessWidget {
  final String title;
  final List<Category> categories;
  final Color accent;
  // Only true for the income section when no wallet is designated
  final bool showSalaryWalletBanner;

  const CategorySection({
    super.key,
    required this.title,
    required this.categories,
    required this.accent,
    this.showSalaryWalletBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Column(
          children: [
            // ── SECTION TITLE ──
            Container(
              padding: const EdgeInsets.all(14),
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontSize: 16,
                ),
              ),
            ),

            const Divider(height: 1, color: AppTheme.accent),

            // ── SALARY WALLET BANNER ──
            if (showSalaryWalletBanner) _SalaryWalletBanner(),

            // ── CATEGORY LIST ──
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "No categories added",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              ...categories.map(
                (c) => CategoryTile(category: c, accent: accent),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBER BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _SalaryWalletBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No salary wallet set. Designate one to enable automatic wallet distribution.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => SalaryWalletSetupSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Set up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
