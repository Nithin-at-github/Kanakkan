import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class AnimatedAmount extends StatefulWidget {
  final double amount;
  final TextStyle style;
  final String prefix;
  final bool animate;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const AnimatedAmount({
    super.key,
    required this.amount,
    required this.style,
    this.prefix = "₹",
    this.animate = true,
    this.duration = const Duration(milliseconds: 1000),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutQuart,
  });

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount> {
  bool _start = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _start = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Text(
        "${widget.prefix}${formatAmt(widget.amount)}",
        style: widget.style,
      );
    }
    return TweenAnimationBuilder<double>(
      duration: widget.duration,
      curve: widget.curve,
      tween: Tween<double>(begin: 0, end: _start ? widget.amount : 0),
      builder: (context, value, child) {
        return Text(
          "${widget.prefix}${formatAmt(value)}",
          style: widget.style,
        );
      },
    );
  }
}
