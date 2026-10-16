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
  final String? gitRepoUrl;
  final String? gitBranch;
  final String? gitOwner;
  final String? gitRepoName;
  final String? ownerId;

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
    this.gitRepoUrl,
    this.gitBranch,
    this.gitOwner,
    this.gitRepoName,
    this.ownerId,
  });

  bool get isGitHubProject =>
      gitRepoUrl != null && gitOwner != null && gitRepoName != null;

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
      gitRepoUrl: json['gitRepoUrl'] as String?,
      gitBranch: json['gitBranch'] as String?,
      gitOwner: json['gitOwner'] as String?,
      gitRepoName: json['gitRepoName'] as String?,
      ownerId: json['ownerId'] as String?,
    );
  }

  factory Project.fromWorkspaceRow(Map<String, dynamic> row) {
    return Project(
      id: row['id'].toString(),
      title: row['name']?.toString() ??
          row['git_repo_name']?.toString() ??
          'GitHub project',
      category: 'Productivity Tools',
      difficulty: 'Intermediate',
      description:
          row['description']?.toString() ?? 'GitHub repository workspace',
      features: const [
        'Live GitHub file tree',
        'On-demand workspace loading',
        'Safe personal editing workspace',
      ],
      techStack: const ['GitHub', 'Git'],
      estimatedTime: 'Live repository',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=600',
      htmlTemplate: '',
      cssTemplate: '',
      jsTemplate: '',
      isFeatured: true,
      gitRepoUrl: row['git_repo_url']?.toString(),
      gitBranch: row['git_branch']?.toString(),
      gitOwner: row['git_owner']?.toString(),
      gitRepoName: row['git_repo_name']?.toString(),
      ownerId: row['user_id']?.toString(),
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
      'gitRepoUrl': gitRepoUrl,
      'gitBranch': gitBranch,
      'gitOwner': gitOwner,
      'gitRepoName': gitRepoName,
      'ownerId': ownerId,
    };
  }
}
