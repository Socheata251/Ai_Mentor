import 'package:flutter/material.dart';

import 'screens/OnboardingScreen.dart';
import 'core/theme/app_theme.dart';

/// Switch themes from anywhere (e.g. your Settings screen):
///   themeMode.value = ThemeMode.dark;   // or .light / .system
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

void main() => runApp(const AImentor());

class AImentor extends StatelessWidget {
  const AImentor({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'AI Programming Tutor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        // FAST: switch instantly instead of cross-fading (and re-computing)
        // every color in the tree on each frame.
        themeAnimationDuration: Duration.zero,
        home: const OnboardingScreen(),
      ),
    );
  }
}