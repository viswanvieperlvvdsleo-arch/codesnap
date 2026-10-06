class Project {
  final String id;
  final String title;
  final String category;
  final String difficulty; // "Beginner" | "Intermediate" | "Advanced"
  final String description;
  final List<String> features;
  final List<String> techStack; // ["HTML", "CSS", "JS"]
  final String estimatedTime;
  final String thumbnailUrl;
  final String htmlTemplate;
  final String cssTemplate;
  final String jsTemplate;
  final bool isFeatured;

  Project({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.description,
    required this.features,
    required this.techStack,
    required this.estimatedTime,
    required this.thumbnailUrl,
    required this.htmlTemplate,
    required this.cssTemplate,
    required this.jsTemplate,
    this.isFeatured = false,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      description: json['description'] as String,
      features: List<String>.from(json['features'] as List),
      techStack: List<String>.from(json['techStack'] as List),
      estimatedTime: json['estimatedTime'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      htmlTemplate: json['htmlTemplate'] as String,
      cssTemplate: json['cssTemplate'] as String,
      jsTemplate: json['jsTemplate'] as String,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'difficulty': difficulty,
      'description': description,
      'features': features,
      'techStack': techStack,
      'estimatedTime': estimatedTime,
      'thumbnailUrl': thumbnailUrl,
      'htmlTemplate': htmlTemplate,
      'cssTemplate': cssTemplate,
      'jsTemplate': jsTemplate,
      'isFeatured': isFeatured,
    };
  }
}
