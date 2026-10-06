class TeamShowdown {
  final String id;
  final String teamName;
  final String projectTitle;
  final String growthUpdate;
  int votes;
  final List<String> memberAvatars;
  final String? demoUrl;

  TeamShowdown({
    required this.id,
    required this.teamName,
    required this.projectTitle,
    required this.growthUpdate,
    required this.votes,
    required this.memberAvatars,
    this.demoUrl,
  });

  factory TeamShowdown.fromJson(Map<String, dynamic> json) {
    return TeamShowdown(
      id: json['id'] as String? ?? '',
      teamName: json['teamName'] as String? ?? 'Team',
      projectTitle: json['projectTitle'] as String? ?? 'Project',
      growthUpdate: json['growthUpdate'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      memberAvatars: (json['memberAvatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      demoUrl: json['demoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamName': teamName,
      'projectTitle': projectTitle,
      'growthUpdate': growthUpdate,
      'votes': votes,
      'memberAvatars': memberAvatars,
      'demoUrl': demoUrl,
    };
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String course;
  final String branch;
  final String section;
  final String year;
  final String deadline;
  final String createdAt;
  final String ownerId;
  int submissionCount;
  final String? starterCode;

  // Hackathon / Arena Extensions
  final String prizePool; // e.g. "₹50,000"
  final String eventType; // "Hackathon", "Bounty", "Challenge", "Showdown"
  final String status; // "LIVE", "VOTING", "UPCOMING", "ENDED"
  final List<String> tags;
  int teamsCount;
  int totalVotes;
  final List<TeamShowdown> teams;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.course,
    required this.branch,
    required this.section,
    required this.year,
    required this.deadline,
    required this.createdAt,
    required this.ownerId,
    required this.submissionCount,
    this.starterCode,
    this.prizePool = '₹10,000',
    this.eventType = 'Hackathon',
    this.status = 'LIVE',
    this.tags = const ['Flutter', 'AI', 'Fullstack'],
    this.teamsCount = 12,
    this.totalVotes = 340,
    this.teams = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      course: json['course'] as String? ?? 'General',
      branch: json['branch'] as String? ?? 'All',
      section: json['section'] as String? ?? 'A',
      year: json['year'] as String? ?? '1',
      deadline: json['deadline'] as String,
      createdAt: json['createdAt'] as String,
      ownerId: json['ownerId'] as String,
      submissionCount: json['submissionCount'] as int? ?? 0,
      starterCode: json['starterCode'] as String?,
      prizePool: json['prizePool'] as String? ?? '₹10,000',
      eventType: json['eventType'] as String? ?? 'Hackathon',
      status: json['status'] as String? ?? 'LIVE',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['Flutter', 'AI'],
      teamsCount: json['teamsCount'] as int? ?? 12,
      totalVotes: json['totalVotes'] as int? ?? 0,
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => TeamShowdown.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'course': course,
      'branch': branch,
      'section': section,
      'year': year,
      'deadline': deadline,
      'createdAt': createdAt,
      'ownerId': ownerId,
      'submissionCount': submissionCount,
      'starterCode': starterCode,
      'prizePool': prizePool,
      'eventType': eventType,
      'status': status,
      'tags': tags,
      'teamsCount': teamsCount,
      'totalVotes': totalVotes,
      'teams': teams.map((e) => e.toJson()).toList(),
    };
  }
}
