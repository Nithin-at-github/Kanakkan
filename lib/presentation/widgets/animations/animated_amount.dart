import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class AnimatedAmount extends StatelessWidget {
  final double amount;
  final TextStyle style;
  final String prefix;
  final bool animate;

  const AnimatedAmount({
    super.key,
    required this.amount,
    required this.style,
    this.prefix = "₹",
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return Text(
        "$prefix${formatAmt(amount)}",
        style: style,
      );
    }
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutExpo,
      tween: Tween<double>(begin: 0, end: amount),
      builder: (context, value, child) {
        return Text(
          "$prefix${formatAmt(value)}",
          style: style,
        );
      },
    );
  }
}
