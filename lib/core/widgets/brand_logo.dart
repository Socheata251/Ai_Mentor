import 'package:flutter/material.dart';

/// Displays the robot brand mark, cropping the transparent padding in the PNG.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.size});

  final double size;

  static const _visibleFraction = 0.62;
  static const ImageProvider _image = AssetImage('assets/logo.png');

  @override
  Widget build(BuildContext context) {
    final imageSize = size / _visibleFraction;
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          minWidth: imageSize,
          maxWidth: imageSize,
          minHeight: imageSize,
          maxHeight: imageSize,
          child: const Image(
            image: _image,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

class NavLogo extends StatelessWidget {
  const NavLogo({super.key, required this.size, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: Image.asset(
          'assets/nav_logo.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          color: color,
          colorBlendMode: color == null ? null : BlendMode.srcIn,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
