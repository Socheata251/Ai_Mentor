import '../models/course.dart';

abstract interface class CourseRepository {
  List<Course> courses();
}

/// Sample data from the design. Replace with an API / database repository.
class MockCourseRepository implements CourseRepository {
  const MockCourseRepository();

  @override
  List<Course> courses() => const [
        Course(code: 'CS 201', title: 'Data Structures & Algorithms', topics: 'Trees, Graphs & Sort', semester: 3, progress: 0.85, category: CourseCategory.dataStructures),
        Course(code: 'CS 223', title: 'Object-Oriented Programming', topics: 'Polymorphism & Java', semester: 3, progress: 0.92, category: CourseCategory.oop),
        Course(code: 'CS 230', title: 'Computer Networks', topics: 'TCP/IP & Subnetting Lab', semester: 3, progress: 0.65, category: CourseCategory.networks),
        Course(code: 'CS 226', title: 'Database Management', topics: 'SQL, Normalization & ERD', semester: 4, progress: 0.42, category: CourseCategory.database),
        Course(code: 'CS 262', title: 'Adv. Web Development', topics: 'Fullstack React & REST APIs', semester: 4, progress: 0.95, category: CourseCategory.web),
        Course(code: 'CS 204', title: 'Computer Architecture', topics: 'CPU, Memory & Assembly', semester: 4, progress: 0.30, category: CourseCategory.architecture),
        Course(code: 'CS 361', title: 'Mobile Applications', topics: 'Flutter & State Mgmt', semester: 5, progress: 0.58, category: CourseCategory.mobile),
        Course(code: 'CS 352', title: 'Operating Systems', topics: 'Processes, Threads & Scheduling', semester: 5, progress: 0.50, category: CourseCategory.os),
      ];
}
