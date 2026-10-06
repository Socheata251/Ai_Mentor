import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Shared radii, so every component uses the same shapes.
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 30;
}

/// Builds one complete Material 3 [ThemeData] from an [AppColors] palette.
/// light_theme.dart and dark_theme.dart both call this, so the two modes can
/// never drift apart. Call it ONCE (they store the result in a `final`).
ThemeData buildAppTheme({
  required Brightness brightness,
  required AppColors colors,
}) {
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.dark.gradientStart,
    brightness: brightness,
  ).copyWith(
    primary: colors.gradientStart,
    onPrimary: Colors.white,
    secondary: colors.gradientEnd,
    onSecondary: Colors.white,
    surface: colors.surface,
    onSurface: colors.textStrong,
    onSurfaceVariant: colors.textMuted,
    error: colors.danger,
    outline: colors.border,
    outlineVariant: colors.border,
  );

  final text = AppTypography.textTheme(colors.textStrong, colors.textMuted);

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.page,
    canvasColor: colors.surface,
    textTheme: text,
    primaryTextTheme: text,
    extensions: [colors],
    visualDensity: VisualDensity.standard,

    // FAST: the default M3 sparkle splash compiles a shader the first time it
    // is used (a visible hitch). The ripple does not.
    splashFactory: InkRipple.splashFactory,

    // Native-feeling page transitions.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      },
    ),

    iconTheme: IconThemeData(color: colors.textStrong, size: 22),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: colors.textStrong,
      titleTextStyle: text.titleLarge,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),

    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: isDark ? BorderSide(color: colors.border) : BorderSide.none,
      ),
    ),

    // ---- Buttons -------------------------------------------------------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.ink,
        foregroundColor: colors.onInk,
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.ink,
        foregroundColor: colors.onInk,
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textStrong,
        minimumSize: const Size(64, 52),
        side: BorderSide(color: colors.border),
        shape: const StadiumBorder(),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.gradientStart,
        textStyle: text.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: colors.textStrong),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.ink,
      foregroundColor: colors.onInk,
      elevation: 2,
      shape: const StadiumBorder(),
    ),

    // ---- Inputs --------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      hintStyle: text.bodyMedium?.copyWith(color: colors.textMuted),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: inputBorder(colors.border),
      enabledBorder: inputBorder(colors.border),
      focusedBorder: inputBorder(colors.gradientStart, 1.5),
      errorBorder: inputBorder(colors.danger),
      focusedErrorBorder: inputBorder(colors.danger, 1.5),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.gradientStart,
      selectionColor: colors.gradientStart.withValues(alpha: 0.25),
      selectionHandleColor: colors.gradientStart,
    ),

    // ---- Navigation ----------------------------------------------------
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.ink,
      elevation: 0,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 22,
          color: s.contains(WidgetState.selected)
              ? colors.onInk
              : colors.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelSmall?.copyWith(
          letterSpacing: 0,
          color: s.contains(WidgetState.selected)
              ? colors.textStrong
              : colors.textMuted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colors.surface,
      indicatorColor: colors.ink,
      selectedIconTheme: IconThemeData(color: colors.onInk),
      unselectedIconTheme: IconThemeData(color: colors.textMuted),
      selectedLabelTextStyle: text.labelMedium,
      unselectedLabelTextStyle:
          text.labelMedium?.copyWith(color: colors.textMuted),
    ),
    drawerTheme: DrawerThemeData(
      width: 304,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.horizontal(right: Radius.circular(AppRadius.xl)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colors.tileIcon,
      textColor: colors.textStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),

    // ---- Controls & feedback ------------------------------------------
    chipTheme: ChipThemeData(
      backgroundColor: colors.tile,
      selectedColor: colors.ink,
      labelStyle: text.labelMedium?.copyWith(color: colors.tileIcon),
      secondaryLabelStyle: text.labelMedium?.copyWith(color: colors.onInk),
      checkmarkColor: colors.onInk,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? colors.gradientStart
            : colors.border,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? colors.gradientStart
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: BorderSide(color: colors.border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.gradientStart,
      linearTrackColor: colors.border,
      circularTrackColor: colors.border,
    ),
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: colors.border,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: colors.onInk),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      textStyle: text.bodySmall?.copyWith(color: colors.onInk),
    ),
  );
}
