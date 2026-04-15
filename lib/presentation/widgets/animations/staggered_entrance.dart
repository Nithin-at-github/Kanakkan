import 'package:flutter/material.dart';

enum EntranceType { fade, slideUp, slideRight, scale, flip }

class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayIncrement;
  final EntranceType type;
  final Duration duration;
  final Curve curve;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delayIncrement = const Duration(milliseconds: 60),
    this.type = EntranceType.slideUp,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutQuart,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    Future.delayed(widget.delayIncrement * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.type) {
          case EntranceType.fade:
            return Opacity(
              opacity: _animation.value,
              child: child,
            );
          case EntranceType.slideUp:
            return Opacity(
              opacity: _animation.value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - _animation.value)),
                child: child,
              ),
            );
          case EntranceType.slideRight:
            return Opacity(
              opacity: _animation.value,
              child: Transform.translate(
                offset: Offset(-30 * (1 - _animation.value), 0),
                child: child,
              ),
            );
          case EntranceType.scale:
            return Opacity(
              opacity: _animation.value,
              child: Transform.scale(
                scale: 0.8 + (0.2 * _animation.value),
                child: child,
              ),
            );
          case EntranceType.flip:
            return Opacity(
              opacity: _animation.value,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX((1 - _animation.value) * 0.5),
                alignment: Alignment.center,
                child: child,
              ),
            );
        }
      },
      child: widget.child,
    );
  }
}
