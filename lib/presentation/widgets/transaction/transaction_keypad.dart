import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class TransactionKeypad extends StatelessWidget {
  final Function(String) onKeyTap;

  const TransactionKeypad({super.key, required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    final keys = ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", ".", "⌫"];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(35, 5, 35, 14),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (_, i) {
        return _KeypadButton(
          label: keys[i],
          onTap: onKeyTap,
        );
      },
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final String label;
  final Function(String) onTap;

  const _KeypadButton({required this.label, required this.onTap});

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () => widget.onTap(widget.label),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accent),
            color: Colors.transparent, // Ensure it captures taps
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(fontSize: 22, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
