import 'package:flutter/material.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final double scaleFactor;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.scaleFactor = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _handlePointerDown(PointerDownEvent event) {
    setState(() => _isPressed = true);
  }

  void _handlePointerUp(PointerUpEvent event) {
    setState(() => _isPressed = false);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
