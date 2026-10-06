import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

// One import gives screens everything:  import '.../core/theme/app_theme.dart';
export 'app_colors.dart';
export 'app_gradients.dart';
export 'app_typography.dart';
export 'theme_builder.dart' show AppRadius;

/// Entry point used by MaterialApp:
///   theme: AppTheme.light, darkTheme: AppTheme.dark
class AppTheme {
  AppTheme._();

  // FAST: both are built once (see light_theme.dart / dark_theme.dart).
  static final ThemeData light = lightTheme;
  static final ThemeData dark = darkTheme;
}
