import 'package:flutter/material.dart';

import '../../../data/models/course.dart';

/// Icon + accent color for each course category.
class CourseStyle {
  const CourseStyle(this.icon, this.color);
  final IconData icon;
  final Color color;

  static CourseStyle of(CourseCategory c) => switch (c) {
        CourseCategory.dataStructures => const CourseStyle(Icons.account_tree_outlined, Color(0xFF7C6CF0)),
        CourseCategory.oop => const CourseStyle(Icons.code_rounded, Color(0xFFF59E0B)),
        CourseCategory.networks => const CourseStyle(Icons.language_rounded, Color(0xFF9333EA)),
        CourseCategory.database => const CourseStyle(Icons.storage_rounded, Color(0xFF06B6D4)),
        CourseCategory.web => const CourseStyle(Icons.desktop_windows_outlined, Color(0xFF10B981)),
        CourseCategory.mobile => const CourseStyle(Icons.smartphone_rounded, Color(0xFFEC4899)),
        CourseCategory.architecture => const CourseStyle(Icons.memory_rounded, Color(0xFF3B82F6)),
        CourseCategory.os => const CourseStyle(Icons.terminal_rounded, Color(0xFFEAB308)),
      };
}
