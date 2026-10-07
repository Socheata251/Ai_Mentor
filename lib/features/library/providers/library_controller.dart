import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../data/models/course.dart';
import '../../../data/repositories/course_repository.dart';

/// Search + semester filter for the Library. The filtered list is computed
/// only when the query / filter changes, never during build.
class LibraryController extends ChangeNotifier {
  LibraryController({CourseRepository repository = const MockCourseRepository()})
      : _all = repository.courses();

  final List<Course> _all;
  late List<Course> _visible = _all;
  int? _semester; // null = all
  String _query = '';

  UnmodifiableListView<Course> get courses => UnmodifiableListView(_visible);
  int? get selectedSemester => _semester;

  /// [3, 4, 5] ...
  List<int> get semesters =>
      (_all.map((c) => c.semester).toSet().toList()..sort());

  void selectSemester(int? semester) {
    if (semester == _semester) return;
    _semester = semester;
    _refilter();
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _refilter();
  }

  void _refilter() {
    _visible = _all
        .where((c) => (_semester == null || c.semester == _semester) && c.matches(_query))
        .toList(growable: false);
    notifyListeners();
  }
}
