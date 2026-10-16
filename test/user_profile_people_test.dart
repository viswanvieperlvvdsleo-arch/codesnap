import 'package:codesnap/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps only database people directory fields into a profile', () {
    final profile = UserProfile.fromPeopleDirectory({
      'id': '9f30cf5d-aed5-48dc-b8c1-75c50736f185',
      'username': 'real_dev',
      'full_name': 'Real Developer',
      'avatar_url': 'https://example.com/avatar.png',
      'headline': 'Flutter engineer',
      'bio': 'Builds production apps.',
      'department': 'Engineering',
      'location': 'Chennai',
      'github_handle': 'real-dev',
      'skills': ['Flutter', 'Postgres'],
      'snapped_count': 12,
      'snapping_count': 4,
      'posts_count': 7,
      'is_snapping': true,
    });

    expect(profile.id, '9f30cf5d-aed5-48dc-b8c1-75c50736f185');
    expect(profile.name, 'Real Developer');
    expect(profile.handle, '@real_dev');
    expect(profile.followersCount, 12);
    expect(profile.followingCount, 4);
    expect(profile.postsCount, 7);
    expect(profile.skills, ['Flutter', 'Postgres']);
    expect(profile.githubHandle, 'real-dev');
    expect(profile.isFollowing, isTrue);
    expect(profile.posts, isEmpty);
    expect(profile.projects, isEmpty);
  });

  test('empty optional database fields do not create mock content', () {
    final profile = UserProfile.fromPeopleDirectory({
      'id': '283801d1-d88f-4b99-b528-b8f9dc9f1d37',
      'username': 'member',
      'skills': null,
    });

    expect(profile.name, 'member');
    expect(profile.handle, '@member');
    expect(profile.avatarUrl, isEmpty);
    expect(profile.bio, isEmpty);
    expect(profile.headline, isEmpty);
    expect(profile.skills, isEmpty);
    expect(profile.followersCount, 0);
    expect(profile.postsCount, 0);
  });
}
