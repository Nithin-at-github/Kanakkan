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
    this.duration = const Duration(milliseconds: 600),
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
    final String formatted = formatAmt(widget.amount);
    final String fullText = "${widget.prefix}$formatted";

    if (!widget.animate || !_start) {
      return Opacity(
        opacity: !_start && widget.animate ? 0 : 1,
        child: Text(fullText, style: widget.style),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _buildAnimatedCharacters(fullText),
    );
  }

  List<Widget> _buildAnimatedCharacters(String text) {
    final List<Widget> widgets = [];
    final characters = text.characters.toList();

    for (int i = 0; i < characters.length; i++) {
      widgets.add(
        _RollingCharacter(
          key: ValueKey("pos_$i"),
          char: characters[i],
          style: widget.style,
          duration: widget.duration,
          curve: widget.curve,
        ),
      );
    }
    return widgets;
  }
}

class _RollingCharacter extends StatelessWidget {
  final String char;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  const _RollingCharacter({
    super.key,
    required this.char,
    required this.style,
    required this.duration,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[...previousChildren, currentChild!],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool isNew = child.key == ValueKey(char);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: isNew ? const Offset(0, 0.4) : const Offset(0, -0.4),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(char, key: ValueKey(char), style: style),
    );
  }
}
