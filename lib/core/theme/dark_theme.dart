import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'theme_builder.dart';

/// Dark mode. `final` top-level variables are created lazily, ONCE.
final ThemeData darkTheme = buildAppTheme(
  brightness: Brightness.dark,
  colors: AppColors.dark,
);
