import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';

/// Small round blue-purple badge shown next to every AI message.
class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.brand,
      ),
      alignment: Alignment.center,
      child: NavLogo(size: size * 0.88, color: Colors.white),
    );
  }
}
