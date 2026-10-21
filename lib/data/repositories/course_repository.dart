import '../models/course.dart';

abstract interface class CourseRepository {
  List<Course> courses();
}

/// BS in Computer Science (Software Engineering): 8 semesters, 120 credits.
/// Source: the school curriculum PDF. Progress starts at 0 for every course.
class MockCourseRepository implements CourseRepository {
  const MockCourseRepository();

  @override
  List<Course> courses() => const [
        Course(code: 'CS 101', title: 'A+', topics: 'PC hardware, OS setup & troubleshooting', semester: 1, credits: 3, category: CourseCategory.foundation),
        Course(code: 'ENG 106', title: 'English for Computing', topics: 'Technical English & IT vocabulary', semester: 1, credits: 3, category: CourseCategory.language),
        Course(code: 'KHM 101', title: 'Khmer Studies', topics: 'Khmer language, culture & history', semester: 1, credits: 3, category: CourseCategory.language),
        Course(code: 'MAT 101', title: 'Mathematics for Computing', topics: 'Logic, sets, number systems & functions', semester: 1, credits: 3, category: CourseCategory.math),
        Course(code: 'MIT 101', title: 'Business IT and Fintech Concept', topics: 'Business IT, digital banking & fintech', semester: 1, credits: 3, category: CourseCategory.business),
        Course(code: 'CS 105', title: 'Web Design', topics: 'HTML, CSS & responsive layout', semester: 2, credits: 3, category: CourseCategory.web),
        Course(code: 'CS 106', title: 'C# .NET Programming', topics: 'C# syntax, OOP & .NET', semester: 2, credits: 6, category: CourseCategory.programming),
        Course(code: 'CS 107', title: 'SQL Server', topics: 'T-SQL, joins, indexes & stored procedures', semester: 2, credits: 6, category: CourseCategory.database),
        Course(code: 'CS 211', title: 'UX/UI Design', topics: 'User research, wireframes & prototyping', semester: 3, credits: 3, category: CourseCategory.design),
        Course(code: 'CS 212', title: 'Web Development I', topics: 'JavaScript, DOM & front-end basics', semester: 3, credits: 3, category: CourseCategory.web),
        Course(code: 'CS 213', title: 'Data Structure & Algorithm', topics: 'Lists, trees, graphs, sorting & Big-O', semester: 3, credits: 3, category: CourseCategory.dataStructures),
        Course(code: 'CS 214', title: 'Java Programming', topics: 'Java OOP, collections & exceptions', semester: 3, credits: 6, category: CourseCategory.oop),
        Course(code: 'CS 216', title: 'Web Development II', topics: 'Server-side web apps & databases', semester: 4, credits: 3, category: CourseCategory.web),
        Course(code: 'CS 217', title: 'API-Web Service', topics: 'REST, JSON & web services', semester: 4, credits: 3, category: CourseCategory.api),
        Course(code: 'CS 218', title: 'Mobile App. Dev. for Android', topics: 'Android apps, UI & data storage', semester: 4, credits: 6, category: CourseCategory.mobile),
        Course(code: 'CS 219', title: 'Oracle', topics: 'Oracle SQL, PL/SQL & administration', semester: 4, credits: 3, category: CourseCategory.database),
        Course(code: 'CS 321', title: 'Mobile App. Dev. for iOS', topics: 'Swift, UIKit/SwiftUI & app lifecycle', semester: 5, credits: 6, category: CourseCategory.mobile),
        Course(code: 'IT 307', title: 'Computer Networking', topics: 'OSI/TCP-IP, IP addressing & protocols', semester: 5, credits: 3, category: CourseCategory.networks),
        Course(code: 'IT 301', title: 'Server Administration I', topics: 'Server OS setup, users & services', semester: 5, credits: 3, category: CourseCategory.os),
        Course(code: 'STA 308', title: 'Data Analytics', topics: 'Statistics, data cleaning & visualization', semester: 5, credits: 3, category: CourseCategory.analytics),
        Course(code: 'CS 326', title: 'DevOps', topics: 'CI/CD, containers & automation', semester: 6, credits: 3, category: CourseCategory.devops),
        Course(code: 'EE 306', title: 'Basic Electronic', topics: 'Circuits, components & digital logic', semester: 6, credits: 3, category: CourseCategory.electronics),
        Course(code: 'IT 302', title: 'Server Administration II', topics: 'Directory services, security & backup', semester: 6, credits: 3, category: CourseCategory.os),
        Course(code: 'IT 334', title: 'CCNA', topics: 'Routing, switching & network configuration', semester: 6, credits: 3, category: CourseCategory.networks),
        Course(code: 'PHI 310', title: 'Soft Skills in Digital Era', topics: 'Communication, teamwork & digital ethics', semester: 6, credits: 3, category: CourseCategory.softSkills),
        Course(code: 'CS 431', title: 'Cloud Technology', topics: 'Cloud models, virtualization & services', semester: 7, credits: 3, category: CourseCategory.cloud),
        Course(code: 'EE 411', title: 'Internet of Things (IoT)', topics: 'Sensors, microcontrollers & IoT protocols', semester: 7, credits: 3, category: CourseCategory.iot),
        Course(code: 'IT 411', title: 'Project Management', topics: 'Planning, scheduling, risk & Agile', semester: 7, credits: 3, category: CourseCategory.management),
        Course(code: 'MGT 403', title: 'Entrepreneurship', topics: 'Business ideas, startups & planning', semester: 7, credits: 3, category: CourseCategory.business),
        Course(code: 'RES 408', title: 'Research Methods in Science and Technology', topics: 'Research design, writing & citation', semester: 7, credits: 3, category: CourseCategory.research),
        Course(code: 'IT 416', title: 'Cyber Security', topics: 'Threats, cryptography & defense', semester: 8, credits: 3, category: CourseCategory.security),
        Course(code: 'IT 419', title: 'Management Information System', topics: 'Information systems in organizations', semester: 8, credits: 3, category: CourseCategory.management),
        Course(code: 'FPR 405', title: 'Final Project Report', topics: 'Capstone project for TGPA 3.60 or higher', semester: 8, credits: 9, category: CourseCategory.research),
        Course(code: 'CS 421', title: 'Software Quality Assurance', topics: 'Elective: testing & QA processes', semester: 8, credits: 3, category: CourseCategory.qa),
        Course(code: 'EE 417', title: 'Robotic Process Automation (RPA)', topics: 'Elective: automating business workflows', semester: 8, credits: 3, category: CourseCategory.automation),
        Course(code: 'EE 418', title: 'Artificial Intelligence', topics: 'Elective: machine learning & AI basics', semester: 8, credits: 3, category: CourseCategory.ai),
        Course(code: 'MKT 417', title: 'Digital Marketing', topics: 'Elective: online marketing & analytics', semester: 8, credits: 3, category: CourseCategory.business),
      ];
}