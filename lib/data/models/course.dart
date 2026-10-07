import 'package:flutter/foundation.dart';

enum CourseCategory {
  dataStructures,
  oop,
  networks,
  database,
  web,
  mobile,
  architecture,
  os,
}

@immutable
class Course {
  const Course({
    required this.code,
    required this.title,
    required this.topics,
    required this.semester,
    required this.category,
    this.credits = 3,
    this.progress = 0,
  });

  final String code; // CS 201
  final String title; // Data Structures & Algorithms
  final String topics; // Trees, Graphs & Sort
  final int semester;
  final int credits;
  final double progress; // 0..1
  final CourseCategory category;

  int get percent => (progress * 100).round();

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        code.toLowerCase().contains(q) ||
        topics.toLowerCase().contains(q);
  }
}
