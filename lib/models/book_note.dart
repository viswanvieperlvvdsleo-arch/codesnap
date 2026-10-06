import 'package:flutter/material.dart';

class BookChapter {
  final int number;
  final String title;
  final String duration;
  final String summary;

  const BookChapter({
    required this.number,
    required this.title,
    required this.duration,
    required this.summary,
  });
}

class BookReviewItem {
  final String authorName;
  final String authorRole;
  final double rating;
  final String date;
  final String comment;
  final String avatarInitials;

  const BookReviewItem({
    required this.authorName,
    required this.authorRole,
    required this.rating,
    required this.date,
    required this.comment,
    required this.avatarInitials,
  });
}

class BookNote {
  final String id;
  final String title;
  final String subtitle;
  final String author;
  final String category; // 'Programming' | 'DSA' | 'Web Dev' | 'AI/ML' | 'Resources'
  final double rating;
  final int reviewCount;
  final int pages;
  final String price; // '₹199' | '₹249' | 'Free'
  final bool isFree;
  final String? badge; // 'Bestseller' | 'Top Rated' | 'New' | 'Editor Choice'
  final Color primaryColor;
  final Color secondaryColor;
  final IconData categoryIcon;
  final String coverCodeSnippet;
  final String description;
  final List<String> keyTakeaways;
  final String fullReviewSummary;
  final List<BookReviewItem> reviews;
  final List<BookChapter> chapters;
  final String readTime;
  final String difficulty; // 'Beginner' | 'Intermediate' | 'Advanced'
  final bool isFeatured;
  bool isBookmarked;
  final String? pdfUrl;
  final String? coverImageUrl;

  BookNote({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.author,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.pages,
    required this.price,
    this.isFree = false,
    this.badge,
    required this.primaryColor,
    required this.secondaryColor,
    required this.categoryIcon,
    required this.coverCodeSnippet,
    required this.description,
    required this.keyTakeaways,
    required this.fullReviewSummary,
    required this.reviews,
    required this.chapters,
    required this.readTime,
    required this.difficulty,
    this.isFeatured = false,
    this.isBookmarked = false,
    this.pdfUrl,
    this.coverImageUrl,
  });
}

class BookNoteData {
  static List<BookNote> getAllBooks() {
    return [
      // 1. Python Crash Course
      BookNote(
        id: 'python-crash-course',
        title: 'Python Crash Course',
        subtitle: 'A Hands-On, Project-Based Introduction to Programming',
        author: 'Eric Matthes',
        category: 'Programming',
        rating: 4.8,
        reviewCount: 3840,
        pages: 544,
        price: '₹199',
        badge: 'Bestseller',
        isFeatured: true,
        primaryColor: const Color(0xFF1E222A),
        secondaryColor: const Color(0xFF2E3440),
        categoryIcon: Icons.code_rounded,
        coverCodeSnippet: 'def python():\n    return "crash_course"',
        description:
            'A fast-paced, thorough introduction to programming with Python that will have you writing programs, solving problems, and making things that work in no time. You\'ll learn basic programming concepts, like lists, dictionaries, classes, and loops, and practice writing clean code.',
        keyTakeaways: [
          'Master fundamental Python syntax & data structures',
          'Build practical web apps with Django',
          'Generate data visualizations using Matplotlib',
          'Test code effectively using pytest'
        ],
        fullReviewSummary:
            'Eric Matthes nails the balance between clarity and real-world applicability. The book splits cleanly between core syntax and 3 complete projects (an arcade game, a web app, and data visualizations). Highly recommended for newcomers and developers switching from other languages.',
        reviews: const [
          BookReviewItem(
            authorName: 'Alex Rivera',
            authorRole: 'Backend Engineer @ Stripe',
            rating: 5.0,
            date: '2 days ago',
            comment:
                'Hands down the most accessible programming book I\'ve read. The project-based second half keeps you motivated all the way through.',
            avatarInitials: 'AR',
          ),
          BookReviewItem(
            authorName: 'Priya Sharma',
            authorRole: 'Data Scientist',
            rating: 4.7,
            date: '1 week ago',
            comment:
                'Clear explanations on lists, dicts, and comprehensions. The data visualizer project was a great launchpad for my career.',
            avatarInitials: 'PS',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'Getting Started & Environment', duration: '45m', summary: 'Setting up Python 3, virtualenvs, and VS Code.'),
          BookChapter(number: 2, title: 'Variables & Simple Data Types', duration: '1h 10m', summary: 'Strings, numbers, floats, and zen of Python.'),
          BookChapter(number: 3, title: 'Introducing Lists & Tuples', duration: '1h 30m', summary: 'Index manipulation, slicing, and immutability.'),
          BookChapter(number: 4, title: 'Working with Dictionaries', duration: '1h 45m', summary: 'Key-value mappings, nesting, and iteration patterns.'),
          BookChapter(number: 5, title: 'User Input & While Loops', duration: '1h 15m', summary: 'Interactive CLI tools and flow management.'),
          BookChapter(number: 6, title: 'Functions & Modules', duration: '2h', summary: 'Parameters, return values, importing, and packaging.'),
          BookChapter(number: 7, title: 'Object-Oriented Programming', duration: '2h 30m', summary: 'Classes, inheritance, and encapsulation.'),
        ],
        readTime: '14 hrs',
        difficulty: 'Beginner',
      ),

      // 2. JavaScript: The Definitive Guide
      BookNote(
        id: 'javascript-definitive-guide',
        title: 'JavaScript: The Definitive Guide',
        subtitle: 'Master the World\'s Most-Used Programming Language',
        author: 'David Flanagan',
        category: 'Web Dev',
        rating: 4.7,
        reviewCount: 2910,
        pages: 704,
        price: '₹249',
        badge: 'Top Rated',
        isFeatured: true,
        primaryColor: const Color(0xFF22242B),
        secondaryColor: const Color(0xFF30343F),
        categoryIcon: Icons.language_rounded,
        coverCodeSnippet: 'const JS = {\n  type: "definitive",\n  edition: "7th"\n};',
        description:
            'Since 1996, JavaScript: The Definitive Guide has been the bible for JavaScript programmers. The 7th edition covers ECMAScript 2020, modern web platform APIs, asynchronous programming with async/await, and modern tooling with Webpack and Vite.',
        keyTakeaways: [
          'Deep understanding of closures, prototypes, and scope chains',
          'Master async/await, Promises, and the Event Loop',
          'Modern DOM manipulation and fetch streaming',
          'Metaprogramming with Proxies and Reflect'
        ],
        fullReviewSummary:
            'An exhaustive, deeply authoritative reference. While dense, David Flanagan explains edge cases and runtime behavior that you simply will not find in medium posts or short tutorials.',
        reviews: const [
          BookReviewItem(
            authorName: 'Marcus Vance',
            authorRole: 'Frontend Architect @ Vercel',
            rating: 4.8,
            date: '3 days ago',
            comment:
                'Whenever someone asks how JavaScript works under the hood, I point them directly to chapters 6 through 9 of this masterpiece.',
            avatarInitials: 'MV',
          ),
          BookReviewItem(
            authorName: 'Sarah Jenkins',
            authorRole: 'Full Stack Dev',
            rating: 4.6,
            date: '2 weeks ago',
            comment:
                'The chapter on the Event Loop and Promises is worth the entire price alone.',
            avatarInitials: 'SJ',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'Introduction to JavaScript', duration: '40m', summary: 'History, ECMAScript standards, and modern engines.'),
          BookChapter(number: 2, title: 'Types, Values, and Variables', duration: '1h 20m', summary: 'Primitives, objects, type coercions, and const/let.'),
          BookChapter(number: 3, title: 'Expressions and Operators', duration: '1h 10m', summary: 'Bitwise, logical nullish coalescing, optional chaining.'),
          BookChapter(number: 4, title: 'Objects & Prototypes', duration: '2h 15m', summary: 'Prototypes, property descriptors, and object identity.'),
          BookChapter(number: 5, title: 'Functions & Closures', duration: '2h 45m', summary: 'Higher order functions, call/apply/bind, lexical scope.'),
          BookChapter(number: 6, title: 'Asynchronous JavaScript', duration: '3h', summary: 'Callbacks, Promises, microtask queues, and async/await.'),
        ],
        readTime: '18 hrs',
        difficulty: 'Intermediate',
      ),

      // 3. Data Structures & Algorithms in Java
      BookNote(
        id: 'dsa-in-java',
        title: 'DSA in Java',
        subtitle: 'Data Structures & Algorithms Made Intuitive',
        author: 'Robert Lafore',
        category: 'DSA',
        rating: 4.9,
        reviewCount: 4120,
        pages: 800,
        price: '₹229',
        badge: 'New',
        isFeatured: true,
        primaryColor: const Color(0xFF1B2028),
        secondaryColor: const Color(0xFF28303C),
        categoryIcon: Icons.account_tree_rounded,
        coverCodeSnippet: 'class GraphNode {\n  List<Edge> edges;\n  int weight;\n}',
        description:
            'A legendary, highly visual guide to Data Structures and Algorithms. Robert Lafore breaks down complex concepts like Red-Black Trees, Dijkstra\'s Algorithm, and Dynamic Programming into intuitive visual animations and clear Java code.',
        keyTakeaways: [
          'Visual understanding of arrays, linked lists, stacks, and queues',
          'Trees & Graphs: BST, AVL, Red-Black Trees, and Heaps',
          'Graph Traversals (BFS, DFS, Dijkstra, Prim)',
          'Algorithmic Complexity & Big-O notation mastery'
        ],
        fullReviewSummary:
            'The single best book for cracking FAANG algorithmic rounds. It eschews hyper-academic math notation in favor of crystal-clear diagrams and runnable Java code.',
        reviews: const [
          BookReviewItem(
            authorName: 'Rohan Gupta',
            authorRole: 'Software Engineer @ Google',
            rating: 5.0,
            date: '5 days ago',
            comment:
                'I used this book to prep for Google L4 interviews. The visual explanations of tree rotations and dynamic programming are unmatched.',
            avatarInitials: 'RG',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'Overview & Big-O Notation', duration: '1h', summary: 'Time and space complexity with practical benchmarking.'),
          BookChapter(number: 2, title: 'Arrays & Ordered Arrays', duration: '1h 15m', summary: 'Linear vs Binary search and memory layout.'),
          BookChapter(number: 3, title: 'Simple Sorting Algorithms', duration: '1h 30m', summary: 'Bubble sort, selection sort, and insertion sort.'),
          BookChapter(number: 4, title: 'Stacks and Queues', duration: '2h', summary: 'LIFO, FIFO, priority queues, and parsing postfix expressions.'),
          BookChapter(number: 5, title: 'Linked Lists & Doubly Linked', duration: '2h 15m', summary: 'Pointer manipulation, sentinels, and cyclic detection.'),
          BookChapter(number: 6, title: 'Binary Trees & Balanced Trees', duration: '3h', summary: 'BST traversals, deletion cases, and AVL balancing.'),
        ],
        readTime: '22 hrs',
        difficulty: 'Intermediate',
      ),

      // 4. Clean Code
      BookNote(
        id: 'clean-code',
        title: 'Clean Code',
        subtitle: 'A Handbook of Agile Software Craftsmanship',
        author: 'Robert C. Martin (Uncle Bob)',
        category: 'Programming',
        rating: 4.6,
        reviewCount: 5120,
        pages: 464,
        price: '₹179',
        badge: 'Staff Pick',
        isFeatured: true,
        primaryColor: const Color(0xFF1E2422),
        secondaryColor: const Color(0xFF2C3532),
        categoryIcon: Icons.auto_fix_high_rounded,
        coverCodeSnippet: '// Clean Code:\nfunction clean() {\n  return true;\n}',
        description:
            'Even bad code can function. But if code isn\'t clean, it can bring a development organization to its knees. Uncle Bob Martin presents a revolutionary paradigm with his craftsmanship manifesto.',
        keyTakeaways: [
          'Writing meaningful names and small, single-purpose functions',
          'Formatting code for readability and maintainability',
          'Complete error handling without cluttering business logic',
          'Unit testing & Test-Driven Development (TDD) principles'
        ],
        fullReviewSummary:
            'Essential reading for every software engineer who wants their code to be readable 6 months later. It transforms how you think about naming, function sizes, and code cleanliness.',
        reviews: const [
          BookReviewItem(
            authorName: 'Elena Rostova',
            authorRole: 'Tech Lead @ Spotify',
            rating: 4.7,
            date: '1 day ago',
            comment:
                'We make this required reading for every onboarding engineer on our team.',
            avatarInitials: 'ER',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'Meaningful Names', duration: '45m', summary: 'Intent-revealing names, avoiding disinformation, pronunciation.'),
          BookChapter(number: 2, title: 'Functions Should Do One Thing', duration: '1h 20m', summary: 'Function arguments, side effects, command query separation.'),
          BookChapter(number: 3, title: 'Comments as Failures', duration: '50m', summary: 'Self-documenting code vs stale misleading comments.'),
          BookChapter(number: 4, title: 'Formatting & Structure', duration: '1h', summary: 'Vertical openness, newspaper metaphor, indentation rules.'),
        ],
        readTime: '10 hrs',
        difficulty: 'Intermediate',
      ),

      // 5. Java: The Complete Reference
      BookNote(
        id: 'java-complete-reference',
        title: 'Java: The Complete Reference',
        subtitle: 'Comprehensive Coverage of the Java Language & Core APIs',
        author: 'Herbert Schildt',
        category: 'Programming',
        rating: 4.8,
        reviewCount: 3200,
        pages: 1200,
        price: '₹299',
        badge: null,
        isFeatured: false,
        primaryColor: const Color(0xFF222026),
        secondaryColor: const Color(0xFF33303A),
        categoryIcon: Icons.coffee_rounded,
        coverCodeSnippet: 'public static void main(\n  String[] args\n) {\n  System.out.println();\n}',
        description:
            'Fully updated for Java SE 17, this definitive resource explains how to develop, compile, debug, and run Java programs. Bestselling programming author Herb Schildt covers the entire Java language, including its syntax, keywords, and fundamental programming principles.',
        keyTakeaways: [
          'In-depth multithreading and the Java Concurrency Utilities',
          'Generics, Lambdas, and the Stream API',
          'Modern features: Records, Sealed Classes, Pattern Matching',
          'Java I/O, NIO, and Networking'
        ],
        fullReviewSummary:
            'The gold standard reference manual for Java developers. It leaves no keyword or API unexamined.',
        reviews: const [
          BookReviewItem(
            authorName: 'Daniel Craig',
            authorRole: 'Senior Java Dev',
            rating: 4.9,
            date: '4 days ago',
            comment: 'Herbert Schildt remains unmatched in thoroughness. A desktop companion for life.',
            avatarInitials: 'DC',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'The History and Evolution of Java', duration: '45m', summary: 'Bytecode, JVM architecture, and platform independence.'),
          BookChapter(number: 2, title: 'Data Types, Variables, and Arrays', duration: '1h 30m', summary: 'Strong typing, integer & floating types, multidimensional arrays.'),
          BookChapter(number: 3, title: 'Operators & Control Statements', duration: '1h 15m', summary: 'Control flows, enhanced switches, and pattern matching.'),
          BookChapter(number: 4, title: 'Multithreaded Programming', duration: '2h 45m', summary: 'Threads, Runnable, synchronization, inter-thread communication.'),
        ],
        readTime: '30 hrs',
        difficulty: 'Advanced',
      ),

      // 6. The C Programming Language
      BookNote(
        id: 'c-programming-language',
        title: 'The C Programming Language',
        subtitle: 'ANSI C Specification & Classic Systems Guide',
        author: 'Brian W. Kernighan, Dennis M. Ritchie',
        category: 'Programming',
        rating: 4.9,
        reviewCount: 6540,
        pages: 272,
        price: '₹149',
        badge: 'Classic',
        isFeatured: false,
        primaryColor: const Color(0xFF1E2128),
        secondaryColor: const Color(0xFF2C313C),
        categoryIcon: Icons.terminal_rounded,
        coverCodeSnippet: '#include <stdio.h>\nint main(void) {\n    printf("hello");\n}',
        description:
            'Written by the creators of C, this authoritative book teaches how to program in C with elegance and precision. It covers pointers, structs, low-level memory access, and the Unix systems interface.',
        keyTakeaways: [
          'Pointers, arrays, and pointer arithmetic mastered',
          'Memory allocation: malloc, calloc, and free',
          'Bitwise operators and masking',
          'Unix system calls and standard library implementation'
        ],
        fullReviewSummary:
            'Short, sharp, and timeless. K&R teaches you how computers actually process information at the byte level.',
        reviews: const [
          BookReviewItem(
            authorName: 'Ken Thompson',
            authorRole: 'Systems Hacker',
            rating: 5.0,
            date: '1 month ago',
            comment: 'Every programmer should read this at least once in their career.',
            avatarInitials: 'KT',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'A Tutorial Introduction', duration: '1h', summary: 'Hello world, variables, arithmetic, while/for, arrays, character input.'),
          BookChapter(number: 2, title: 'Types, Operators, Expressions', duration: '1h 15m', summary: 'Constants, declarations, type conversions, bitwise operators.'),
          BookChapter(number: 3, title: 'Pointers and Arrays', duration: '2h 30m', summary: 'Address-of operator, dereferencing, pointer arithmetic, character pointers.'),
          BookChapter(number: 4, title: 'Structures & Unions', duration: '2h', summary: 'Struct basics, array of structures, self-referential structures.'),
        ],
        readTime: '8 hrs',
        difficulty: 'Advanced',
      ),

      // 7. HTML & CSS: The Definitive Guide
      BookNote(
        id: 'html-css-guide',
        title: 'HTML & CSS: The Definitive Guide',
        subtitle: 'Modern Responsive Layouts, Flexbox, & Grid Mastery',
        author: 'Eric A. Meyer',
        category: 'Web Dev',
        rating: 4.7,
        reviewCount: 1890,
        pages: 600,
        price: '₹189',
        badge: null,
        isFeatured: false,
        primaryColor: const Color(0xFF23222A),
        secondaryColor: const Color(0xFF353440),
        categoryIcon: Icons.web_rounded,
        coverCodeSnippet: '.container {\n  display: grid;\n  gap: 1.5rem;\n}',
        description:
            'Unlock the full creative power of the web. Learn modern CSS architecture, custom properties (variables), subgrid, container queries, and accessibility best practices from Eric Meyer.',
        keyTakeaways: [
          'Complete CSS Grid and Flexbox mental models',
          'CSS Custom Properties and dynamic design systems',
          'Container Queries and responsive fluid typography',
          'Web accessibility (WCAG 2.1) and semantic HTML'
        ],
        fullReviewSummary:
            'Eric Meyer provides deep clarity on the cascading algorithm, specificity, and modern layout engines that eliminate layout headaches.',
        reviews: const [
          BookReviewItem(
            authorName: 'Clara Oswald',
            authorRole: 'UI/UX Engineer',
            rating: 4.8,
            date: '3 days ago',
            comment: 'Finally demystified CSS Grid vs Flexbox for me. Highly recommended!',
            avatarInitials: 'CO',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'Semantic HTML Foundation', duration: '50m', summary: 'Document outline, landmark roles, and accessible markup.'),
          BookChapter(number: 2, title: 'The Cascade & Specificity', duration: '1h 10m', summary: 'Inheritance, cascade layers (@layer), specificity calculation.'),
          BookChapter(number: 3, title: 'Modern Flexbox in Practice', duration: '1h 45m', summary: 'Main axis, cross axis, flex-basis, and distribution algorithms.'),
          BookChapter(number: 4, title: 'CSS Grid & Subgrid', duration: '2h 20m', summary: 'Implicit vs explicit grid, fractional units, and named grid lines.'),
        ],
        readTime: '12 hrs',
        difficulty: 'Beginner',
      ),

      // 8. Machine Learning for Beginners
      BookNote(
        id: 'machine-learning-beginners',
        title: 'Machine Learning for Beginners',
        subtitle: 'Intuitive Math, Scikit-Learn, & Neural Networks',
        author: 'Jason Brownlee',
        category: 'AI/ML',
        rating: 4.8,
        reviewCount: 3450,
        pages: 320,
        price: '₹249',
        badge: 'Trending',
        isFeatured: false,
        primaryColor: const Color(0xFF1E2625),
        secondaryColor: const Color(0xFF2C3836),
        categoryIcon: Icons.psychology_rounded,
        coverCodeSnippet: 'model = RandomForest(\n  n_estimators=100\n)\nmodel.fit(X, y)',
        description:
            'Machine learning is not magic; it is applied mathematics and optimization. Discover how algorithms learn from data, train regression and classification models, and step into deep learning with PyTorch.',
        keyTakeaways: [
          'Linear Regression, Logistic Regression, and Decision Trees',
          'Feature engineering, normalization, and handling missing data',
          'Model evaluation: Cross-validation, ROC-AUC, and Confusion Matrix',
          'Foundations of Neural Networks and backpropagation'
        ],
        fullReviewSummary:
            'Crisp, practical tutorials without getting stuck in academic math proofs. Excellent stepping stone into real AI work.',
        reviews: const [
          BookReviewItem(
            authorName: 'Vikram Patel',
            authorRole: 'ML Engineer',
            rating: 4.9,
            date: '1 week ago',
            comment: 'Dr. Brownlee’s approach of coding first and explaining math second is brilliant.',
            avatarInitials: 'VP',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'What is Machine Learning?', duration: '40m', summary: 'Supervised vs unsupervised learning and the ML workflow.'),
          BookChapter(number: 2, title: 'Data Cleaning & Preprocessing', duration: '1h 15m', summary: 'Scaling, one-hot encoding, and train-test splits.'),
          BookChapter(number: 3, title: 'Classification Algorithms', duration: '2h', summary: 'KNN, Logistic Regression, Random Forests, and XGBoost.'),
          BookChapter(number: 4, title: 'Introduction to Deep Learning', duration: '2h 30m', summary: 'Perceptrons, activation functions, loss curves, and PyTorch.'),
        ],
        readTime: '11 hrs',
        difficulty: 'Beginner',
      ),

      // 9. System Design Primer
      BookNote(
        id: 'system-design-primer',
        title: 'System Design Interview & Architecture',
        subtitle: 'Scalable Systems, Microservices, & Distributed Databases',
        author: 'Alex Xu',
        category: 'DSA',
        rating: 4.9,
        reviewCount: 7800,
        pages: 340,
        price: '₹299',
        badge: 'Top Rated',
        isFeatured: false,
        primaryColor: const Color(0xFF212028),
        secondaryColor: const Color(0xFF31303C),
        categoryIcon: Icons.hub_rounded,
        coverCodeSnippet: 'class LoadBalancer {\n  Algorithm: "round_robin"\n  Replicas: 4\n}',
        description:
            'The step-by-step insider guide to designing large-scale distributed systems. Learn how to architect systems like YouTube, Twitter, and WhatsApp from scratch.',
        keyTakeaways: [
          'CAP theorem, consistent hashing, and database sharding',
          'Message queues: Kafka, RabbitMQ, and event-driven architecture',
          'Caching strategies: Write-through, Write-back, and Cache-aside',
          'Rate limiting, CDN, and high availability principles'
        ],
        fullReviewSummary:
            'A masterclass in real-world systems architecture. Every diagram is crisp and directly reflects questions asked in top tech company rounds.',
        reviews: const [
          BookReviewItem(
            authorName: 'Nathan Cole',
            authorRole: 'Staff Infrastructure Architect',
            rating: 5.0,
            date: '4 days ago',
            comment: 'The clearest explanation of distributed systems available anywhere.',
            avatarInitials: 'NC',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'Scale From Zero To Millions', duration: '1h', summary: 'Vertical vs Horizontal scaling, load balancers, database replication.'),
          BookChapter(number: 2, title: 'Back-of-the-envelope Estimation', duration: '45m', summary: 'Latency numbers, throughput calculations, and storage sizing.'),
          BookChapter(number: 3, title: 'Design a Rate Limiter', duration: '1h 30m', summary: 'Token bucket, leaky bucket, sliding window counter algorithms.'),
          BookChapter(number: 4, title: 'Design a Distributed Message Queue', duration: '2h 15m', summary: 'Partitioning, consumer groups, offset tracking, durability.'),
        ],
        readTime: '14 hrs',
        difficulty: 'Advanced',
      ),

      // 10. Modern Full-Stack Notes (Free)
      BookNote(
        id: 'modern-fullstack-notes',
        title: 'Modern Full-Stack Next.js 14 Guide',
        subtitle: 'Server Components, Server Actions, & Turbopack',
        author: 'CodeSnap Community',
        category: 'Resources',
        rating: 4.8,
        reviewCount: 1650,
        pages: 180,
        price: 'Free',
        isFree: true,
        badge: 'Free',
        isFeatured: false,
        primaryColor: const Color(0xFF20222A),
        secondaryColor: const Color(0xFF303440),
        categoryIcon: Icons.menu_book_rounded,
        coverCodeSnippet: 'export default async function Page() {\n  const data = await getPosts();\n}',
        description:
            'A free, open-source cheat sheet and reference guide for building lightning fast web applications with Next.js App Router, React Server Components, Tailwind CSS, and Prisma ORM.',
        keyTakeaways: [
          'Mental model for React Server Components vs Client Components',
          'Data mutations with Server Actions and revalidation',
          'Route handlers, streaming with Suspense, and optimistic UI',
          'Production deployment with Docker and edge runtimes'
        ],
        fullReviewSummary:
            'An incredible community-contributed guide that is constantly updated with real-world patterns.',
        reviews: const [
          BookReviewItem(
            authorName: 'Liam Wright',
            authorRole: 'Indie Hacker',
            rating: 4.9,
            date: '1 day ago',
            comment: 'Saved me countless hours navigating Next.js 14 cache semantics.',
            avatarInitials: 'LW',
          ),
        ],
        chapters: const [
          BookChapter(number: 1, title: 'App Router Core Architecture', duration: '35m', summary: 'File-based routing, layouts, error boundaries, and loading states.'),
          BookChapter(number: 2, title: 'Server Components & Streaming', duration: '1h', summary: 'Streaming SSR, Suspense boundaries, and zero-bundle JS.'),
          BookChapter(number: 3, title: 'Server Actions & Forms', duration: '1h 20m', summary: 'Form validation with Zod, useFormStatus, and useOptimistic.'),
        ],
        readTime: '6 hrs',
        difficulty: 'Intermediate',
      ),
    ];
  }
}
