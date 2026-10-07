import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';

const _serif = TextStyle(
  fontFamily: 'Georgia',
  fontFamilyFallback: ['Times New Roman', 'serif'],
);

/// Floating logo + tagline + greeting at the top of the home screen.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.float,
    required this.greeting,
    required this.name,
    this.maxLogoSize = 150,
    this.titleSize = 30,
  });

  final Animation<Offset> float;
  final String greeting, name;
  final double maxLogoSize;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FloatingLogo(float: float, maxSize: maxLogoSize),
        const SizedBox(height: 14),
        const _Tagline(),
        const SizedBox(height: 14),
        _Greeting(greeting: greeting, name: name, titleSize: titleSize),
      ],
    );
  }
}

class _FloatingLogo extends StatelessWidget {
  const _FloatingLogo({required this.float, required this.maxSize});
  final Animation<Offset> float;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 440.0;
        final logoSize = (availableWidth * 0.37)
            .clamp(124.0, maxSize)
            .toDouble();
        return SizedBox(
          height: logoSize + 8,
          child: Center(
            child: RepaintBoundary(
              child: SlideTransition(
                position: float,
                child: BrandLogo(size: logoSize),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavLogo(size: 22, color: colors.textStrong),
          const SizedBox(width: 8),
          Text(
            'PERSONAL KNOWLEDGE COMPANION',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              color: colors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.greeting,
    required this.name,
    required this.titleSize,
  });

  final String greeting, name;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          '$greeting,',
          textAlign: TextAlign.center,
          style: _serif.copyWith(
            color: colors.textStrong,
            fontSize: titleSize,
            height: 1.1,
          ),
        ),
        Text(
          name,
          textAlign: TextAlign.center,
          style: _serif.copyWith(
            color: colors.textStrong,
            fontSize: titleSize,
            height: 1.15,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ready to start studying with AUB today?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: colors.textMuted),
        ),
      ],
    );
  }
}
