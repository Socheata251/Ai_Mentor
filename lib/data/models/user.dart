import 'package:flutter/foundation.dart';

/// The student using the app.
@immutable
class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    this.university = 'ACLEDA University',
    this.semester = 4,
  });

  final String name;
  final String email;
  final String university;
  final int semester;

  String get initial {
    final n = name.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? university,
    int? semester,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      university: university ?? this.university,
      semester: semester ?? this.semester,
    );
  }
}