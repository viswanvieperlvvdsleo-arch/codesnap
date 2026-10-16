import 'package:flutter_test/flutter_test.dart';
import 'package:codesnap/models/task.dart';
import 'package:codesnap/services/upload_status_service.dart';

void main() {
  test('Arena team maps Supabase snake_case fields', () {
    final team = TeamShowdown.fromJson({
      'id': 'team-id',
      'owner_id': 'owner-id',
      'team_name': 'Builders',
      'project_title': 'Live project',
      'growth_update': 'Connected to Supabase',
      'votes_count': 7,
      'member_avatars': ['https://example.com/avatar.png'],
      'repo_url': 'https://github.com/example/project',
    });

    expect(team.teamName, 'Builders');
    expect(team.projectTitle, 'Live project');
    expect(team.votes, 7);
    expect(team.ownerId, 'owner-id');
    expect(team.repoUrl, 'https://github.com/example/project');
  });

  test('Upload ring begins half yellow and accepts progress', () {
    final upload = UploadStatusService.instance;

    upload.start(label: 'Publishing story');
    expect(upload.state, UploadState.uploading);
    expect(upload.progress, 0.5);

    upload.update(0.85);
    expect(upload.progress, 0.85);
  });
}
