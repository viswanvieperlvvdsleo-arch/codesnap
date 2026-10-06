class User {
  final String id;
  final String name;
  final String email;
  final String? section;
  String avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.section,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      section: json['section'] as String?,
      avatarUrl: json['avatarUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'section': section,
      'avatarUrl': avatarUrl,
    };
  }
}
