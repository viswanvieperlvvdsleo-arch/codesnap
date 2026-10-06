class LearnContent {
  final int day;
  final String category; // "HTML" | "CSS" | "JavaScript"
  final String title;
  final String theory;
  final String codeExample;
  final String task;

  LearnContent({
    required this.day,
    required this.category,
    required this.title,
    required this.theory,
    required this.codeExample,
    required this.task,
  });

  factory LearnContent.fromJson(Map<String, dynamic> json) {
    return LearnContent(
      day: json['day'] as int,
      category: json['category'] as String,
      title: json['title'] as String,
      theory: json['theory'] as String,
      codeExample: json['codeExample'] as String,
      task: json['task'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'category': category,
      'title': title,
      'theory': theory,
      'codeExample': codeExample,
      'task': task,
    };
  }
}
