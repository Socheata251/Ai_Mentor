import 'package:flutter/material.dart';

/// Fade + slide-up entrance. FadeTransition avoids the offscreen layer that
/// `Opacity` creates, and [child] is built once (not every frame).
class StaggerIn extends StatelessWidget {
  const StaggerIn({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, c) => Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child: c,
        ),
      ),
    );
  }
}
