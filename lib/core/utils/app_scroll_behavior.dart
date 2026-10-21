import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Lets every scrollable be dragged with a mouse, trackpad or stylus too, not
/// only by touch. Without this, lists on the website / desktop only move with
/// the mouse wheel.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };
}