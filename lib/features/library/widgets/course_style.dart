import 'package:flutter/material.dart';

import '../../../data/models/course.dart';

/// Icon + accent color for each course category.
class CourseStyle {
  const CourseStyle(this.icon, this.color);
  final IconData icon;
  final Color color;

  static CourseStyle of(CourseCategory c) => switch (c) {
        CourseCategory.foundation => const CourseStyle(Icons.computer_rounded, Color(0xFF64748B)),
        CourseCategory.language => const CourseStyle(Icons.translate_rounded, Color(0xFFEF4444)),
        CourseCategory.math => const CourseStyle(Icons.calculate_rounded, Color(0xFF0EA5E9)),
        CourseCategory.business => const CourseStyle(Icons.business_center_outlined, Color(0xFFF97316)),
        CourseCategory.web => const CourseStyle(Icons.desktop_windows_outlined, Color(0xFF10B981)),
        CourseCategory.programming => const CourseStyle(Icons.code_rounded, Color(0xFF6366F1)),
        CourseCategory.database => const CourseStyle(Icons.storage_rounded, Color(0xFF06B6D4)),
        CourseCategory.design => const CourseStyle(Icons.draw_outlined, Color(0xFFD946EF)),
        CourseCategory.dataStructures => const CourseStyle(Icons.account_tree_outlined, Color(0xFF7C6CF0)),
        CourseCategory.oop => const CourseStyle(Icons.data_object_rounded, Color(0xFFF59E0B)),
        CourseCategory.api => const CourseStyle(Icons.api_rounded, Color(0xFF14B8A6)),
        CourseCategory.mobile => const CourseStyle(Icons.smartphone_rounded, Color(0xFFEC4899)),
        CourseCategory.networks => const CourseStyle(Icons.language_rounded, Color(0xFF9333EA)),
        CourseCategory.os => const CourseStyle(Icons.terminal_rounded, Color(0xFFEAB308)),
        CourseCategory.analytics => const CourseStyle(Icons.bar_chart_rounded, Color(0xFF22C55E)),
        CourseCategory.devops => const CourseStyle(Icons.sync_alt_rounded, Color(0xFF3B82F6)),
        CourseCategory.electronics => const CourseStyle(Icons.memory_rounded, Color(0xFF84CC16)),
        CourseCategory.softSkills => const CourseStyle(Icons.groups_rounded, Color(0xFFF43F5E)),
        CourseCategory.cloud => const CourseStyle(Icons.cloud_outlined, Color(0xFF38BDF8)),
        CourseCategory.iot => const CourseStyle(Icons.sensors_rounded, Color(0xFF16A34A)),
        CourseCategory.management => const CourseStyle(Icons.event_note_rounded, Color(0xFFA855F7)),
        CourseCategory.research => const CourseStyle(Icons.science_outlined, Color(0xFF8B5CF6)),
        CourseCategory.security => const CourseStyle(Icons.security_rounded, Color(0xFFDC2626)),
        CourseCategory.qa => const CourseStyle(Icons.bug_report_outlined, Color(0xFFCA8A04)),
        CourseCategory.automation => const CourseStyle(Icons.smart_toy_outlined, Color(0xFF0D9488)),
        CourseCategory.ai => const CourseStyle(Icons.psychology_outlined, Color(0xFF2563EB)),
      };
}