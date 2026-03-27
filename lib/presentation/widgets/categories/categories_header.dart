import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class CategoriesHeader extends StatelessWidget {
  final double totalWallet;
  final String topCategoryName;
  final double topCategoryAmount;

  const CategoriesHeader({
    super.key,
    required this.totalWallet,
    required this.topCategoryName,
    required this.topCategoryAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: Column(
        children: [
          Text(
            "Categories",
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard(
                "Total Wallets",
                "₹${formatAmt(totalWallet)}",
                Colors.white,
              ),
              _summaryCard(
                "Top Wallet",
                "$topCategoryName${topCategoryName.isNotEmpty ? ': ' : ''}₹${formatAmt(topCategoryAmount)}",
                AppTheme.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String content, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
