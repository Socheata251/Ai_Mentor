import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/api_config.dart';
import 'core/network/api_client.dart';
import 'core/router/app_nav.dart';
import 'core/utils/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/user_session.dart';
import 'data/services/ai_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/remote_ai_service.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

/// Switch themes from anywhere (e.g. your Settings screen):
///   themeMode.value = ThemeMode.dark;   // or .light / .system
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (ApiConfig.useBackend) AiServices.current = const RemoteAiService();

  // Refresh token rejected -> back to Sign in.
  ApiClient.instance.onSessionExpired = () {
    AuthService.instance.logout();
    AppNav.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  };

  // Stay signed in between launches.
  final signedIn = await AuthService.instance.restoreSession();
  runApp(AImentor(signedIn: signedIn));
}

class AImentor extends StatelessWidget {
  const AImentor({super.key, this.signedIn = false});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        navigatorKey: AppNav.navigatorKey,
        title: 'Astra Learn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        // FAST: switch instantly instead of cross-fading (and re-computing)
        // every color in the tree on each frame.
        themeAnimationDuration: Duration.zero,
        // Mouse / trackpad drag scrolling for the website and desktop.
        scrollBehavior: const AppScrollBehavior(),
        // Respect the user's font size, but stop extreme sizes from breaking
        // layouts on phones, tablets and the web.
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final icons = isDark ? Brightness.light : Brightness.dark;
          // Status / navigation bar icons stay readable in light and dark
          // mode on Android and iOS.
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: icons, // Android
              statusBarBrightness: isDark
                  ? Brightness.dark
                  : Brightness.light, // iOS
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: icons,
              systemNavigationBarContrastEnforced: false,
            ),
            child: MediaQuery(
              data: media.copyWith(
                textScaler: media.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.3,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: signedIn
            ? DashboardScreen(userName: UserSession.instance.name)
            : const OnboardingScreen(),
      ),
    );
  }
}