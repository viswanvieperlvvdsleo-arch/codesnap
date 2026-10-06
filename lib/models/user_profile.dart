class UserMediaItem {
  final String id;
  String title;
  final String type; // 'image' | 'video'
  final String mediaUrl;
  final String thumbnailUrl;
  final String fileSize; // e.g. "2.4 MB", "18.5 MB"
  final String? duration; // e.g. "0:45", "2:15" (for videos)
  final int likesCount;
  final int viewsCount;
  final String timestamp;

  bool hideLikes;
  bool hideComments;
  bool hidePost;

  UserMediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.fileSize,
    this.duration,
    required this.likesCount,
    required this.viewsCount,
    required this.timestamp,
    this.hideLikes = false,
    this.hideComments = false,
    this.hidePost = false,
  });

  bool get isVideo => type == 'video';
}

class UserPostItem {
  final String id;
  String content;
  final String? codeSnippet;
  final String? language;
  int likesCount;
  final int commentsCount;
  final String timestamp;
  bool isLiked;
  bool hideLikes;
  bool hideComments;
  bool hidePost;

  UserPostItem({
    required this.id,
    required this.content,
    this.codeSnippet,
    this.language,
    required this.likesCount,
    required this.commentsCount,
    required this.timestamp,
    this.isLiked = false,
    this.hideLikes = false,
    this.hideComments = false,
    this.hidePost = false,
  });
}

class UserProjectItem {
  final String id;
  final String title;
  final String description;
  final int stars;
  final int forks;
  final List<String> techStack;

  UserProjectItem({
    required this.id,
    required this.title,
    required this.description,
    required this.stars,
    required this.forks,
    required this.techStack,
  });
}

class UserProfile {
  final String id;
  String name;
  String handle; // e.g. "@alexj"
  String avatarUrl;
  String bannerUrl;
  String headline;
  String bio;
  String roleBadge; // e.g. "Pro Contributor", "Mentor", "Core Dev"
  String department; // e.g. "CSE · 3rd Year"
  String location;
  int followersCount;
  int followingCount;
  int postsCount;
  int? mediaCount;
  List<String> badges;
  List<String> tags;
  List<String> skills;
  bool isOnline;
  bool isFollowing;
  List<UserMediaItem> mediaItems;
  List<UserPostItem> posts;
  List<UserProjectItem> projects;

  UserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    required this.bannerUrl,
    required this.headline,
    this.bio = '',
    required this.roleBadge,
    this.department = '',
    this.location = '',
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    this.mediaCount,
    this.badges = const [],
    this.tags = const [],
    List<String>? skills,
    this.isOnline = false,
    this.isFollowing = false,
    List<UserMediaItem>? mediaItems,
    List<dynamic>? media,
    List<UserPostItem>? posts,
    List<UserProjectItem>? projects,
  })  : skills = skills ?? tags ?? const [],
        mediaItems = mediaItems ?? const [],
        posts = posts ?? const [],
        projects = projects ?? const [];
}
