class TeamShowdown {
  final String id;
  final String teamName;
  final String projectTitle;
  final String growthUpdate;
  int votes;
  final List<String> memberAvatars;
  final String? demoUrl;
  final String ownerId;
  final String? repoUrl;

  TeamShowdown({
    required this.id,
    required this.teamName,
    required this.projectTitle,
    required this.growthUpdate,
    required this.votes,
    required this.memberAvatars,
    this.demoUrl,
    this.ownerId = '',
    this.repoUrl,
  });

  factory TeamShowdown.fromJson(Map<String, dynamic> json) {
    return TeamShowdown(
      id: json['id'] as String? ?? '',
      teamName: (json['teamName'] ?? json['team_name']) as String? ?? 'Team',
      projectTitle:
          (json['projectTitle'] ?? json['project_title']) as String? ??
              'Project',
      growthUpdate:
          (json['growthUpdate'] ?? json['growth_update']) as String? ?? '',
      votes: ((json['votes'] ?? json['votes_count']) as num?)?.toInt() ?? 0,
      memberAvatars:
          ((json['memberAvatars'] ?? json['member_avatars']) as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      demoUrl: (json['demoUrl'] ?? json['demo_url']) as String?,
      ownerId: json['owner_id'] as String? ?? '',
      repoUrl: json['repo_url'] as String?,
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
      'ownerId': ownerId,
      'repoUrl': repoUrl,
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
  final String ownerName;
  final String ownerAvatarUrl;
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
  final bool isBookmarked;
  final String? currentUserTeamId;

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
    this.ownerName = 'Arena host',
    this.ownerAvatarUrl = '',
    required this.submissionCount,
    this.starterCode,
    this.prizePool = '₹10,000',
    this.eventType = 'Hackathon',
    this.status = 'LIVE',
    this.tags = const ['Flutter', 'AI', 'Fullstack'],
    this.teamsCount = 12,
    this.totalVotes = 340,
    this.teams = const [],
    this.isBookmarked = false,
    this.currentUserTeamId,
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
      ownerName: json['ownerName'] as String? ?? 'Arena host',
      ownerAvatarUrl: json['ownerAvatarUrl'] as String? ?? '',
      submissionCount: json['submissionCount'] as int? ?? 0,
      starterCode: json['starterCode'] as String?,
      prizePool: json['prizePool'] as String? ?? '₹10,000',
      eventType: json['eventType'] as String? ?? 'Hackathon',
      status: json['status'] as String? ?? 'LIVE',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              ['Flutter', 'AI'],
      teamsCount: json['teamsCount'] as int? ?? 12,
      totalVotes: json['totalVotes'] as int? ?? 0,
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => TeamShowdown.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      currentUserTeamId: json['currentUserTeamId'] as String?,
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
      'ownerName': ownerName,
      'ownerAvatarUrl': ownerAvatarUrl,
      'submissionCount': submissionCount,
      'starterCode': starterCode,
      'prizePool': prizePool,
      'eventType': eventType,
      'status': status,
      'tags': tags,
      'teamsCount': teamsCount,
      'totalVotes': totalVotes,
      'teams': teams.map((e) => e.toJson()).toList(),
      'isBookmarked': isBookmarked,
      'currentUserTeamId': currentUserTeamId,
    };
  }
}
