import 'package:flutter/material.dart';

class PageTransitions {
  static Route<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> slideUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

class FadeThroughTransition extends StatelessWidget {
  const FadeThroughTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryAnimation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
          child: child,
        ),
      ),
    );
  }
}
