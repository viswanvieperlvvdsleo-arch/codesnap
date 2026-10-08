import 'user_profile.dart';

class User {
  final String id;
  String name;
  final String email;
  String? section;
  String avatarUrl;
  String? headline;
  String? bio;
  String? department;
  String? location;
  List<String> skills;
  String? bannerUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.section,
    required this.avatarUrl,
    this.headline,
    this.bio,
    this.department,
    this.location,
    this.skills = const [],
    this.bannerUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Developer',
      email: json['email'] as String? ?? '',
      section: json['section'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      department: json['department'] as String?,
      location: json['location'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      bannerUrl: json['bannerUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'section': section,
      'avatarUrl': avatarUrl,
      'headline': headline,
      'bio': bio,
      'department': department,
      'location': location,
      'skills': skills,
      'bannerUrl': bannerUrl,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? section,
    String? avatarUrl,
    String? headline,
    String? bio,
    String? department,
    String? location,
    List<String>? skills,
    String? bannerUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      section: section ?? this.section,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      department: department ?? this.department,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

  UserProfile toUserProfile() {
    return UserProfile(
      id: id,
      name: name,
      handle: section != null && section!.isNotEmpty
          ? '@${section!.replaceAll('@', '')}'
          : '@${email.isNotEmpty ? email.split('@').first : 'user'}',
      avatarUrl: avatarUrl,
      bannerUrl: bannerUrl ?? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200&q=80',
      headline: headline ?? '',
      bio: bio ?? '',
      roleBadge: email.toLowerCase().contains('admin') ? 'Administrator' : 'Developer',
      department: department ?? '',
      location: location ?? '',
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
      skills: skills,
      isOnline: true,
      isFollowing: false,
    );
  }
}
