import '../../core/network/api_client.dart';
import '../models/lesson.dart';

class CourseLessons {
  const CourseLessons({required this.lessons, required this.completedCount});
  final List<LessonSummary> lessons;
  final int completedCount;
}

class LessonPage {
  const LessonPage({required this.lesson, this.prev, this.next});
  final LessonDetail lesson;
  final LessonLink? prev;
  final LessonLink? next;
}

/// Reads the lessons stored in the database (no AI involved).
class LessonService {
  LessonService._();
  static final LessonService instance = LessonService._();

  final ApiClient _api = ApiClient.instance;

  Future<CourseLessons> forCourse(String courseCode) async {
    final data = await _api.get(
      '/api/courses/${Uri.encodeComponent(courseCode)}/lessons',
    ) as Map<String, dynamic>;
    return CourseLessons(
      lessons: [
        for (final l in (data['lessons'] as List).cast<Map<String, dynamic>>())
          LessonSummary.fromJson(l),
      ],
      completedCount: (data['completedCount'] as num).toInt(),
    );
  }

  Future<LessonPage> lesson(int id) async {
    final data = await _api.get('/api/lessons/$id') as Map<String, dynamic>;
    return LessonPage(
      lesson: LessonDetail.fromJson(data['lesson'] as Map<String, dynamic>),
      prev: LessonLink.fromJson(data['prev']),
      next: LessonLink.fromJson(data['next']),
    );
  }

  Future<void> setCompleted(int lessonId, bool completed) async {
    await _api.put('/api/lessons/$lessonId/progress', body: {'completed': completed});
  }
}