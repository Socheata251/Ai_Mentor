import 'package:flutter/material.dart';

/// Screen size groups. Change the numbers below to move the breakpoints.
///   compact  -> phones
///   medium   -> big phones, foldables, tablets
///   expanded -> desktop / laptop / wide web window
enum ScreenSize { compact, medium, expanded }

const double kMediumBreakpoint = 600;
const double kExpandedBreakpoint = 1024;

extension ScreenSizeContext on BuildContext {
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= kExpandedBreakpoint) return ScreenSize.expanded;
    if (width >= kMediumBreakpoint) return ScreenSize.medium;
    return ScreenSize.compact;
  }
}

extension ScreenSizeX on ScreenSize {
  bool get isCompact => this == ScreenSize.compact;
  bool get isExpanded => this == ScreenSize.expanded;

  /// Pick a value per screen size. Missing sizes fall back to the smaller one.
  ///   size.pick(compact: 16, medium: 24, expanded: 32)
  T pick<T>({required T compact, T? medium, T? expanded}) => switch (this) {
    ScreenSize.compact => compact,
    ScreenSize.medium => medium ?? compact,
    ScreenSize.expanded => expanded ?? medium ?? compact,
  };
}
