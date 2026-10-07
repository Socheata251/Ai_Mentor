import 'package:flutter/material.dart';

/// Static radial glow (const -> built once, cached by a RepaintBoundary).
class HomeBackGlow extends StatelessWidget {
  const HomeBackGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 340,
      height: 340,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0x6E6C93FF), Color(0x1F6C93FF), Color(0x006C93FF)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
