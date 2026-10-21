// LESSON CONTENT (W3Schools style, no AI needed to read it).
// Edit this file, then run:  npm run lessons:build  &&  npm run db:init
//
// Block types:  heading | text | code | output | tip
//   text  supports `inline code`, **bold** and lines that start with "• " (bullets)
//   code  needs a language (html, css, js, py, sql, dart, java ...)

const h = (text) => ({ type: 'heading', text });
const p = (...lines) => ({ type: 'text', text: lines.join('\n') });
const code = (language, source) => ({ type: 'code', language, code: source.trim() });
const out = (text) => ({ type: 'output', text });
const tip = (text) => ({ type: 'tip', text });

export const COURSES = [
  // ---------------------------------------------------------------- CS 212
  {
    course: 'CS 212',
    lessons: [
      {
        slug: 'html-structure',
        title: 'HTML Page Structure',
        summary: 'Tags, elements and the parts every web page has.',
        blocks: [
          p('HTML (HyperText Markup Language) describes the **structure** of a web page. The browser reads the tags and draws the page.'),
          h('A minimal page'),
          code('html', `
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>My first page</title>
  </head>
  <body>
    <h1>Hello, world!</h1>
    <p>This is a paragraph.</p>
  </body>
</html>`),
          p(
            '• `<head>` holds information about the page (title, meta tags, links to CSS).',
            '• `<body>` holds everything the user can see.',
            '• Most elements have an opening tag and a closing tag, like `<p>` and `</p>`.',
          ),
          h('Common elements'),
          code('html', `
<h2>A heading</h2>
<a href="https://example.com">A link</a>
<img src="photo.jpg" alt="A photo" />
<ul>
  <li>First item</li>
  <li>Second item</li>
</ul>`),
          tip('Always write an `alt` text on images. Screen readers use it, and it shows if the image fails to load.'),
        ],
      },
      {
        slug: 'css-box-model',
        title: 'CSS Selectors and the Box Model',
        summary: 'Choose elements with selectors and understand padding, border and margin.',
        blocks: [
          p('CSS (Cascading Style Sheets) controls how HTML looks: colors, spacing and layout.'),
          h('Selectors'),
          code('css', `
/* element selector */
p { color: #333; }

/* class selector (use class="card" in HTML) */
.card { background: white; padding: 16px; }

/* id selector (use id="title" in HTML) */
#title { font-size: 32px; }`),
          p(
            '• An element selector styles every tag of that type.',
            '• A class can be used on many elements. An id should be used only once.',
          ),
          h('The box model'),
          p('Every element is a box made of four layers, from inside to outside: **content**, **padding**, **border** and **margin**.'),
          code('css', `
.card {
  width: 200px;
  padding: 16px;
  border: 2px solid #4f46e5;
  margin: 24px;
}`),
          p('With the default setting the total width is 200 + 16 + 16 + 2 + 2 = **236px**, because padding and border are added to the width.'),
          tip('Add `box-sizing: border-box;` so the width you set already includes the padding and border.'),
        ],
      },
      {
        slug: 'js-variables-functions',
        title: 'JavaScript Variables and Functions',
        summary: 'let, const, and how to write functions.',
        blocks: [
          p('JavaScript makes a page interactive. Use `let` for values that change and `const` for values that must not be reassigned.'),
          code('js', `
let score = 0;        // can change
const name = "Dara";  // cannot be reassigned

score = score + 10;
console.log(name, score);`),
          out('Dara 10'),
          h('Functions'),
          code('js', `
function add(a, b) {
  return a + b;
}

// arrow function (short form)
const double = (n) => n * 2;

console.log(add(2, 3));
console.log(double(4));`),
          out('5\n8'),
          p(
            '• A function can take **parameters** (a, b) and give back a value with `return`.',
            '• Arrow functions are a shorter way to write small functions.',
          ),
          tip('Prefer `const` by default. Use `let` only when you really need to change the value. Avoid `var`.'),
        ],
      },
      {
        slug: 'js-fetch-async',
        title: 'Fetch and async/await',
        summary: 'Load data from a server without freezing the page.',
        blocks: [
          p('Loading data from a server takes time. JavaScript does not wait; it uses a **Promise** that finishes later. `async` and `await` let you write this in a clear, top-to-bottom way.'),
          code('js', `
async function loadUsers() {
  try {
    const response = await fetch("https://api.example.com/users");
    if (!response.ok) {
      throw new Error("Server error: " + response.status);
    }
    const users = await response.json();
    console.log(users.length);
  } catch (error) {
    console.log("Could not load users:", error.message);
  }
}

loadUsers();`),
          p(
            '• `await` pauses the function until the Promise finishes, but the page stays responsive.',
            '• `fetch` does not throw on 404 or 500, so check `response.ok` yourself.',
            '• Use `try / catch` to handle network errors.',
          ),
          tip('To run several requests at the same time, use `await Promise.all([fetch(a), fetch(b)])`.'),
        ],
      },
      {
        slug: 'rest-basics',
        title: 'REST API Basics',
        summary: 'HTTP methods, status codes and a first request.',
        blocks: [
          p('A REST API lets an app talk to a server with simple HTTP requests. Each URL is a **resource**, and the HTTP method says what to do with it.'),
          p(
            '• `GET /api/courses` reads a list.',
            '• `POST /api/courses` creates a new item.',
            '• `PATCH /api/courses/5` changes part of item 5.',
            '• `DELETE /api/courses/5` removes item 5.',
          ),
          h('Status codes'),
          p(
            '• **200** OK, **201** Created, **204** No content.',
            '• **400** Bad request (your input is wrong), **401** Not logged in, **403** Not allowed, **404** Not found.',
            '• **500** Server error.',
          ),
          h('Example request'),
          code('js', `
const response = await fetch("/api/courses", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer " + token,
  },
  body: JSON.stringify({ title: "Web Development" }),
});
console.log(response.status); // 201`),
          tip('Send the login token in the `Authorization` header, never in the URL.'),
        ],
      },
    ],
  },

  // ---------------------------------------------------------------- CS 107
  {
    course: 'CS 107',
    lessons: [
      {
        slug: 'sql-select-where',
        title: 'SELECT and WHERE',
        summary: 'Read rows from a table and filter them.',
        blocks: [
          p('SQL is the language used to read and change data in a relational database. `SELECT` reads rows from a table.'),
          code('sql', `
-- all columns
SELECT * FROM students;

-- only some columns
SELECT name, gpa FROM students;`),
          h('Filtering with WHERE'),
          code('sql', `
SELECT name, gpa
FROM students
WHERE gpa >= 3.5 AND city = 'Phnom Penh';`),
          p(
            '• Compare with `=`, `<>`, `<`, `>`, `<=`, `>=`.',
            '• Combine conditions with `AND`, `OR`, `NOT`.',
            "• Use `LIKE 'A%'` for names that start with A, and `IN ('A', 'B')` for a list.",
          ),
          tip('In standard SQL, text values use single quotes.'),
        ],
      },
      {
        slug: 'sql-order-limit',
        title: 'Sorting and Limiting Results',
        summary: 'ORDER BY, LIMIT and DISTINCT.',
        blocks: [
          code('sql', `
SELECT name, gpa
FROM students
ORDER BY gpa DESC, name ASC
LIMIT 5;`),
          p(
            '• `ORDER BY` sorts the result. `ASC` is low to high (the default), `DESC` is high to low.',
            '• `LIMIT 5` returns only the first 5 rows (the top 5 students).',
            '• `SELECT DISTINCT city FROM students;` shows each city only once.',
          ),
          tip('Without `ORDER BY`, the database may return rows in any order. Always sort when order matters.'),
        ],
      },
      {
        slug: 'sql-joins',
        title: 'JOINs',
        summary: 'Combine rows from two tables.',
        blocks: [
          p('A JOIN combines rows from two tables using a related column, usually a foreign key.'),
          p('Example tables: `students(id, name)` and `enrollments(student_id, course)`.'),
          code('sql', `
SELECT s.name, e.course
FROM students s
INNER JOIN enrollments e ON e.student_id = s.id;`),
          p(
            '• **INNER JOIN** keeps only rows that match in both tables.',
            '• **LEFT JOIN** keeps every row from the left table, even with no match (the missing side is NULL).',
          ),
          code('sql', `
-- students who are not enrolled in any course
SELECT s.name
FROM students s
LEFT JOIN enrollments e ON e.student_id = s.id
WHERE e.student_id IS NULL;`),
          tip('Give tables short aliases (`s`, `e`) so the query is easier to read.'),
        ],
      },
      {
        slug: 'sql-group-by',
        title: 'GROUP BY and HAVING',
        summary: 'Count, sum and average rows in groups.',
        blocks: [
          p('Aggregate functions calculate one value from many rows: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`.'),
          code('sql', `
SELECT COUNT(*) FROM students;   -- number of students
SELECT AVG(gpa) FROM students;   -- average GPA`),
          h('Grouping'),
          code('sql', `
SELECT city, COUNT(*) AS total
FROM students
GROUP BY city
HAVING COUNT(*) > 5
ORDER BY total DESC;`),
          p(
            '• `GROUP BY` makes one result row for each group (each city).',
            '• `WHERE` filters rows **before** grouping. `HAVING` filters groups **after** grouping.',
          ),
          tip('Every column in `SELECT` must either be in `GROUP BY` or be inside an aggregate function.'),
        ],
      },
      {
        slug: 'normalization',
        title: 'Normalization (1NF, 2NF, 3NF)',
        summary: 'Remove repeated data by splitting tables.',
        blocks: [
          p('Normalization organizes tables to remove repeated data and prevent update mistakes.'),
          p(
            '• **1NF**: every cell holds one value (no lists like "Math, Physics" in one cell).',
            '• **2NF**: 1NF, and every non-key column depends on the **whole** primary key (this matters when the key has 2 or more columns).',
            '• **3NF**: 2NF, and no non-key column depends on another non-key column.',
          ),
          h('Example'),
          p('Bad table: `orders(order_id, customer_id, customer_name, customer_city)`. The customer name and city depend on `customer_id`, not on `order_id`. That breaks 3NF.'),
          p('Fix: split it into two tables.'),
          code('sql', `
CREATE TABLE customers (
  customer_id  INT PRIMARY KEY,
  name         VARCHAR(100) NOT NULL,
  city         VARCHAR(100)
);

CREATE TABLE orders (
  order_id     INT PRIMARY KEY,
  customer_id  INT NOT NULL REFERENCES customers(customer_id)
);`),
          tip('If you change a customer name in only one place, the data is probably well normalized.'),
        ],
      },
      {
        slug: 'keys-erd',
        title: 'Keys and ER Diagrams',
        summary: 'Primary keys, foreign keys and relationship types.',
        blocks: [
          p('An **ER diagram** (ERD) shows entities (tables), their attributes (columns) and the relationships between them.'),
          p(
            '• **Primary key**: uniquely identifies each row (cannot be NULL or repeated).',
            '• **Foreign key**: a column that points to the primary key of another table.',
            '• **Unique**: no two rows may have the same value.',
          ),
          h('Relationship types'),
          p(
            '• **1:1**: one user has one profile.',
            '• **1:N**: one teacher has many courses.',
            '• **N:M**: students and courses. You need a third table (a junction table) to store it.',
          ),
          code('sql', `
CREATE TABLE enrollments (
  student_id  INT REFERENCES students(id),
  course_id   INT REFERENCES courses(id),
  PRIMARY KEY (student_id, course_id)
);`),
          tip('To turn an N:M relationship into tables, create a junction table with two foreign keys.'),
        ],
      },
    ],
  },

  // ---------------------------------------------------------------- CS 213
  {
    course: 'CS 213',
    lessons: [
      {
        slug: 'big-o',
        title: 'Big-O Notation',
        summary: 'How running time grows when the input grows.',
        blocks: [
          p('Big-O describes how the running time grows when the input size **n** grows. It ignores small details and shows the trend.'),
          p(
            '• **O(1)** constant: reading `list[0]`.',
            '• **O(log n)** logarithmic: binary search.',
            '• **O(n)** linear: looping through a list once.',
            '• **O(n log n)**: good sorting algorithms such as merge sort.',
            '• **O(n²)**: a loop inside a loop.',
          ),
          code('py', `
def find_max(numbers):          # O(n): one loop
    best = numbers[0]
    for x in numbers:
        if x > best:
            best = x
    return best

def has_duplicate(numbers):     # O(n^2): loop inside a loop
    for i in range(len(numbers)):
        for j in range(i + 1, len(numbers)):
            if numbers[i] == numbers[j]:
                return True
    return False`),
          tip('Drop constants and small terms: O(2n + 5) is just O(n).'),
        ],
      },
      {
        slug: 'stacks-queues',
        title: 'Stacks and Queues',
        summary: 'LIFO and FIFO structures.',
        blocks: [
          p('A **stack** is Last-In, First-Out (LIFO), like a pile of plates. A **queue** is First-In, First-Out (FIFO), like people in a line.'),
          code('py', `
# Stack with a list
stack = []
stack.append(1)
stack.append(2)
print(stack.pop())      # 2 (last in, first out)

# Queue with deque
from collections import deque
queue = deque()
queue.append(1)
queue.append(2)
print(queue.popleft())  # 1 (first in, first out)`),
          out('2\n1'),
          p(
            '• Stack uses: undo button, browser back, checking brackets.',
            '• Queue uses: print jobs, task scheduling, breadth-first search.',
          ),
          tip('Use `deque` for queues. `list.pop(0)` is O(n) and gets slow for big lists.'),
        ],
      },
      {
        slug: 'hash-maps',
        title: 'Hash Maps',
        summary: 'Key and value storage with fast lookup.',
        blocks: [
          p('A hash map (dictionary) stores **key → value** pairs. A hash function turns the key into a position, so lookup is O(1) on average.'),
          code('py', `
ages = {"Dara": 20, "Sophea": 19}

ages["Vanna"] = 21          # add
print(ages["Dara"])         # 20
print(ages.get("Bora", 0))  # 0 (missing key, no error)

for name, age in ages.items():
    print(name, age)`),
          out('20\n0\nDara 20\nSophea 19\nVanna 21'),
          p(
            '• Keys must be unique and hashable (strings, numbers, tuples).',
            '• When two keys land in the same spot it is a **collision**. Hash maps handle it with chaining or probing.',
            '• The worst case lookup can be O(n), but this is rare with a good hash function.',
          ),
          tip('Need to count things? A dictionary is perfect: `counts[word] = counts.get(word, 0) + 1`.'),
        ],
      },
      {
        slug: 'recursion',
        title: 'Recursion',
        summary: 'A function that calls itself, with a base case.',
        blocks: [
          p('A recursive function calls itself on a smaller problem. It needs a **base case** (when to stop) and a **recursive case** (the smaller call).'),
          code('py', `
def factorial(n):
    if n == 0:                   # base case
        return 1
    return n * factorial(n - 1)  # recursive case

print(factorial(4))`),
          out('24'),
          p('How it runs: `factorial(4)` = 4 × `factorial(3)` = 4 × 3 × `factorial(2)` = ... = 4 × 3 × 2 × 1 × 1 = 24.'),
          p(
            '• Without a base case, the function never stops (a stack overflow error).',
            '• Each call uses memory on the call stack.',
          ),
          tip('Plain recursive Fibonacci repeats work and is O(2ⁿ). Store the results (memoization) to make it O(n).'),
        ],
      },
      {
        slug: 'binary-search',
        title: 'Binary Search',
        summary: 'Find a value in a sorted list in O(log n).',
        blocks: [
          p('Binary search finds a value in a **sorted** list by checking the middle and throwing away half of the list each step. It runs in O(log n).'),
          code('py', `
def binary_search(items, target):
    low, high = 0, len(items) - 1
    while low <= high:
        mid = (low + high) // 2
        if items[mid] == target:
            return mid
        if items[mid] < target:
            low = mid + 1
        else:
            high = mid - 1
    return -1

print(binary_search([2, 5, 8, 12, 16, 23], 12))`),
          out('3'),
          p('Searching 1,000,000 items takes only about 20 steps, because 2²⁰ is about one million.'),
          tip('The list must be sorted first. On unsorted data, binary search gives wrong results.'),
        ],
      },
    ],
  },

  // ---------------------------------------------------------------- CS 218
  {
    course: 'CS 218',
    lessons: [
      {
        slug: 'widgets-tree',
        title: 'Widgets and the Widget Tree',
        summary: 'Everything in Flutter is a widget.',
        blocks: [
          p('In Flutter, everything you see is a **widget**: text, buttons, padding, even the whole screen. Widgets are placed inside other widgets and form a **widget tree**.'),
          code('dart', `
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Hello')),
        body: const Center(child: Text('Welcome to Flutter')),
      ),
    );
  }
}`),
          p(
            '• `MaterialApp` sets up the app. `Scaffold` gives the basic page layout (app bar, body).',
            '• `Center` and `Text` are small widgets combined to build the screen.',
            '• The `build` method describes what the widget looks like.',
          ),
          tip('Use `const` in front of widgets that never change. Flutter can then skip rebuilding them.'),
        ],
      },
      {
        slug: 'stateless-stateful',
        title: 'StatelessWidget vs StatefulWidget',
        summary: 'When the screen needs to change, use state.',
        blocks: [
          p('A **StatelessWidget** never changes after it is built. A **StatefulWidget** can change when its data (**state**) changes. Call `setState` to tell Flutter to rebuild.'),
          code('dart', `
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => setState(() => _count++),
      child: Text('Tapped $_count times'),
    );
  }
}`),
          p(
            '• Put values that change (like `_count`) inside the State class.',
            '• Changing a variable without `setState` will not update the screen.',
          ),
          tip('For data shared by many screens, use a state-management tool such as Provider or Riverpod instead of many `setState` calls.'),
        ],
      },
      {
        slug: 'layout-listview',
        title: 'Layout and ListView',
        summary: 'Row, Column and long scrollable lists.',
        blocks: [
          p('`Row` places children side by side, `Column` places them top to bottom. `ListView` shows a long scrollable list.'),
          code('dart', `
Column(
  children: [
    const Text('My courses'),
    Expanded(
      child: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(courses[index].title),
            subtitle: Text(courses[index].code),
          );
        },
      ),
    ),
  ],
)`),
          p(
            '• `ListView.builder` creates items only when they scroll into view, so it is fast for long lists.',
            '• Put a `ListView` inside a `Column` only with `Expanded`, or you get a layout error.',
          ),
          tip('Use `Padding` and `SizedBox(height: 12)` for spacing instead of empty `Text` widgets.'),
        ],
      },
      {
        slug: 'navigation',
        title: 'Navigation Between Screens',
        summary: 'Open a new screen and go back.',
        blocks: [
          p('Flutter keeps screens in a **stack**. `Navigator.push` opens a new screen on top, and `Navigator.pop` goes back.'),
          code('dart', `
// open the detail screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const DetailScreen()),
);

// go back
Navigator.pop(context);`),
          p(
            '• You can pass data by giving the new screen a constructor parameter: `DetailScreen(course: course)`.',
            '• For bigger apps, a package such as `go_router` helps with named routes and deep links.',
          ),
          tip('After an `await` inside a function, check `if (!context.mounted) return;` before using `context` again.'),
        ],
      },
      {
        slug: 'http-api',
        title: 'Calling an API with http',
        summary: 'Load data from your backend.',
        blocks: [
          p('Add the `http` package to `pubspec.yaml`, then call your backend. The result arrives later, so use `async` and `await`.'),
          code('dart', `
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<dynamic>> loadCourses(String token) async {
  final response = await http.get(
    Uri.parse('http://10.0.2.2:3000/api/courses'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode != 200) {
    throw Exception('Server error \${response.statusCode}');
  }
  final data = jsonDecode(utf8.decode(response.bodyBytes));
  return data['courses'] as List<dynamic>;
}`),
          p(
            '• On the Android emulator, `10.0.2.2` means your computer. `localhost` would point to the emulator itself.',
            '• Always handle errors and show a loading state while waiting.',
          ),
          tip('Never put secret keys in the app. Keep them on the server.'),
        ],
      },
    ],
  },

  // ---------------------------------------------------------------- CS 214
  {
    course: 'CS 214',
    lessons: [
      {
        slug: 'classes-objects',
        title: 'Classes and Objects',
        summary: 'A class is a blueprint, an object is one thing made from it.',
        blocks: [
          p('A **class** is a blueprint. An **object** is one thing made from that blueprint. A class has **fields** (data) and **methods** (actions).'),
          code('java', `
public class Student {
    String name;
    double gpa;

    Student(String name, double gpa) {   // constructor
        this.name = name;
        this.gpa = gpa;
    }

    void introduce() {
        System.out.println("Hi, I am " + name);
    }
}

public class Main {
    public static void main(String[] args) {
        Student s = new Student("Dara", 3.6);
        s.introduce();
    }
}`),
          out('Hi, I am Dara'),
          p(
            '• `new` creates an object by calling the constructor.',
            '• `this` means the current object.',
          ),
          tip('Name classes with a capital letter (`Student`) and methods with a small letter (`introduce`).'),
        ],
      },
      {
        slug: 'encapsulation',
        title: 'Encapsulation',
        summary: 'Hide the data and control access with methods.',
        blocks: [
          p('Encapsulation means hiding the data inside a class and giving controlled access through methods. Make fields `private` and use getters and setters.'),
          code('java', `
public class BankAccount {
    private double balance;

    public double getBalance() {
        return balance;
    }

    public void deposit(double amount) {
        if (amount <= 0) {
            throw new IllegalArgumentException("Amount must be positive");
        }
        balance += amount;
    }
}`),
          p(
            '• Other code cannot set `balance` to a wrong value directly.',
            '• The class can check rules (like a positive amount) in one place.',
          ),
          tip('Start with `private` for every field. Open access only when you need it.'),
        ],
      },
      {
        slug: 'inheritance',
        title: 'Inheritance',
        summary: 'Reuse code with extends.',
        blocks: [
          p('Inheritance lets a class (the **subclass**) reuse the fields and methods of another class (the **superclass**) with `extends`. It models an "is-a" relationship: a Dog **is an** Animal.'),
          code('java', `
class Animal {
    void eat() {
        System.out.println("This animal eats");
    }
}

class Dog extends Animal {
    void bark() {
        System.out.println("Woof!");
    }
}

// inside main():
Dog d = new Dog();
d.eat();   // inherited from Animal
d.bark();`),
          out('This animal eats\nWoof!'),
          p(
            '• Use `super(...)` to call the superclass constructor.',
            '• Java allows only one superclass, but a class can implement many interfaces.',
          ),
          tip('Use inheritance for "is-a". For "has-a" (a Car has an Engine) use a field instead.'),
        ],
      },
      {
        slug: 'polymorphism',
        title: 'Polymorphism',
        summary: 'The same method call, different behavior.',
        blocks: [
          p('Polymorphism means "many forms": the same method call can behave differently depending on the real type of the object. A subclass can **override** a method.'),
          code('java', `
class Shape {
    double area() { return 0; }
}

class Circle extends Shape {
    double r;
    Circle(double r) { this.r = r; }
    @Override
    double area() { return Math.PI * r * r; }
}

class Square extends Shape {
    double side;
    Square(double side) { this.side = side; }
    @Override
    double area() { return side * side; }
}

// inside main():
Shape[] shapes = { new Circle(1), new Square(2) };
for (Shape s : shapes) {
    System.out.println(s.area());
}`),
          out('3.141592653589793\n4.0'),
          p('The loop only knows about `Shape`, but Java calls the right `area()` for each object at runtime.'),
          tip('Always add `@Override`. The compiler then warns you if the method name or parameters do not match.'),
        ],
      },
      {
        slug: 'abstraction-interfaces',
        title: 'Abstraction and Interfaces',
        summary: 'Show what an object does, hide how.',
        blocks: [
          p('**Abstraction** shows what an object does and hides how. In Java you use `abstract` classes and `interface`s.'),
          code('java', `
interface Payable {
    void pay(double amount);
}

class CardPayment implements Payable {
    public void pay(double amount) {
        System.out.println("Paid " + amount + " by card");
    }
}

class CashPayment implements Payable {
    public void pay(double amount) {
        System.out.println("Paid " + amount + " in cash");
    }
}`),
          p(
            '• An **interface** lists methods a class must have. A class can implement many interfaces.',
            '• An **abstract class** can mix finished methods with abstract ones, and cannot be created with `new`.',
            '• Code that uses `Payable` does not care which payment type it gets, so you can add new types without changing it.',
          ),
          tip('Prefer an interface when you only need to define behavior. Use an abstract class when subclasses share code.'),
        ],
      },
    ],
  },
];