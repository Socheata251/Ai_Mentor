-- Courses (generated from the Flutter MockCourseRepository)
BEGIN;
INSERT INTO courses (code,title,topics,semester,credits,category) VALUES ('CS 201','Data Structures & Algorithms','Trees, Graphs & Sort',3,3,'dataStructures') ON CONFLICT (code) DO NOTHING;
INSERT INTO courses (code,title,topics,semester,credits,category) VALUES ('CS 223','Object-Oriented Programming','Polymorphism & Java',3,3,'oop') ON CONFLICT (code) DO NOTHING;
INSERT INTO courses (code,title,topics,semester,credits,category) VALUES ('CS 230','Computer Networks','TCP/IP & Subnetting Lab',3,3,'networks') ON CONFLICT (code) DO NOTHING;
INSERT INTO courses (code,title,topics,semester,credits,category) VALUES ('CS 226','Database Management','SQL, Normalization & ERD',4,3,'database') ON CONFLICT (code) DO NOTHING;
INSERT INTO courses (code,title,topics,semester,credits,category) VALUES ('CS 262','Adv. Web Development','Fullstack React & REST APIs',4,3,'web') ON CONFLICT (code) DO NOTHING;
INSERT INTO courses (code,title,topics,semester,credits,category) VALUES ('CS 204','Computer Architecture','CPU, Memory & Assembly',4,3,'architecture') ON CONFLICT (code) DO NOTHING;
INSERT INTO courses (code,title,topics,semester,credits,category) VALUES ('CS 361','Mobile Applications','Flutter & State Mgmt',5,3,'mobile') ON CONFLICT (code) DO NOTHING;
INSERT INTO courses (code,title,topics,semester,credits,category) VALUES ('CS 352','Operating Systems','Processes, Threads & Scheduling',5,3,'os') ON CONFLICT (code) DO NOTHING;
COMMIT;
