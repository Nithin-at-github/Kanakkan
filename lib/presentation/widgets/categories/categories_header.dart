import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/widgets/animations/animated_amount.dart';

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
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: Column(
        children: [
          Text(
            "Categories",
            style: TextStyle(
              color: theme.colorScheme.secondary,
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
                totalWallet,
                Colors.white,
              ),
              _summaryCard(
                "Top Wallet",
                topCategoryAmount,
                theme.colorScheme.secondary,
                prefix: "$topCategoryName${topCategoryName.isNotEmpty ? ': ' : ''}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double amount, Color color, {String? prefix}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          AnimatedAmount(
            amount: amount,
            prefix: prefix ?? "₹",
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
