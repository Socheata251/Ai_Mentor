import 'package:flutter/foundation.dart';

/// One piece of a lesson page (W3Schools style).
sealed class LessonBlock {
  const LessonBlock();
}

final class LessonHeading extends LessonBlock {
  const LessonHeading(this.text);
  final String text;
}

/// Supports `inline code`, **bold** and lines that start with "• ".
final class LessonText extends LessonBlock {
  const LessonText(this.text);
  final String text;
}

final class LessonCode extends LessonBlock {
  const LessonCode(this.code, {this.language});
  final String code;
  final String? language;
}

/// The result of running the example code.
final class LessonOutput extends LessonBlock {
  const LessonOutput(this.text);
  final String text;
}

final class LessonTip extends LessonBlock {
  const LessonTip(this.text);
  final String text;
}

/// Turns one JSON block from the API into a [LessonBlock] (null = unknown type).
LessonBlock? lessonBlockFromJson(Map<String, dynamic> j) {
  final text = j['text'] as String? ?? '';
  switch (j['type']) {
    case 'heading':
      return LessonHeading(text);
    case 'text':
      return LessonText(text);
    case 'code':
      return LessonCode(j['code'] as String? ?? '', language: j['language'] as String?);
    case 'output':
      return LessonOutput(text);
    case 'tip':
      return LessonTip(text);
  }
  return null;
}

/// A row in the lesson list of a course.
@immutable
class LessonSummary {
  const LessonSummary({
    required this.id,
    required this.position,
    required this.title,
    required this.summary,
    required this.completed,
  });

  final int id;
  final int position;
  final String title;
  final String summary;
  final bool completed;

  factory LessonSummary.fromJson(Map<String, dynamic> j) => LessonSummary(
        id: (j['id'] as num).toInt(),
        position: (j['position'] as num).toInt(),
        title: j['title'] as String,
        summary: j['summary'] as String? ?? '',
        completed: j['completed'] as bool? ?? false,
      );
}

/// Previous / next lesson link.
@immutable
class LessonLink {
  const LessonLink({required this.id, required this.title});

  final int id;
  final String title;

  static LessonLink? fromJson(Object? j) => j is Map<String, dynamic>
      ? LessonLink(id: (j['id'] as num).toInt(), title: j['title'] as String)
      : null;
}

/// A full lesson with its content.
@immutable
class LessonDetail {
  const LessonDetail({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.position,
    required this.total,
    required this.title,
    required this.summary,
    required this.blocks,
    required this.completed,
  });

  final int id;
  final String courseCode;
  final String courseTitle;
  final int position;
  final int total;
  final String title;
  final String summary;
  final List<LessonBlock> blocks;
  final bool completed;

  factory LessonDetail.fromJson(Map<String, dynamic> j) => LessonDetail(
        id: (j['id'] as num).toInt(),
        courseCode: j['courseCode'] as String,
        courseTitle: j['courseTitle'] as String,
        position: (j['position'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        title: j['title'] as String,
        summary: j['summary'] as String? ?? '',
        blocks: [
          for (final b in (j['blocks'] as List).cast<Map<String, dynamic>>())
            if (lessonBlockFromJson(b) case final block?) block,
        ],
        completed: j['completed'] as bool? ?? false,
      );
}