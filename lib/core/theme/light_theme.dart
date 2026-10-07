import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'theme_builder.dart';

/// Light mode. `final` top-level variables are created lazily, ONCE.
final ThemeData lightTheme = buildAppTheme(
  brightness: Brightness.light,
  colors: AppColors.light,
);
