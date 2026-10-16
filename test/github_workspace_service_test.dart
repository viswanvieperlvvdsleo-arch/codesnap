import 'package:flutter_test/flutter_test.dart';

import 'package:codesnap/models/project.dart';
import 'package:codesnap/services/github_workspace_service.dart';

void main() {
  test('parses canonical GitHub repository URLs', () {
    final repository = GithubWorkspaceService.parseRepositoryUrl(
      'https://github.com/openai/openai-cookbook.git',
    );

    expect(repository.owner, 'openai');
    expect(repository.name, 'openai-cookbook');
    expect(repository.url, 'https://github.com/openai/openai-cookbook');
  });

  test('rejects non-GitHub repository hosts', () {
    expect(
      () => GithubWorkspaceService.parseRepositoryUrl(
        'https://example.com/owner/repository',
      ),
      throwsFormatException,
    );
  });

  test('recognizes projects with complete GitHub metadata', () {
    final project = Project(
      id: 'project-id',
      title: 'Repository',
      category: 'Productivity Tools',
      difficulty: 'Intermediate',
      description: 'GitHub project',
      features: const [],
      techStack: const [],
      estimatedTime: 'Live repository',
      thumbnailUrl: '',
      htmlTemplate: '',
      cssTemplate: '',
      jsTemplate: '',
      gitRepoUrl: 'https://github.com/owner/repository',
      gitBranch: 'main',
      gitOwner: 'owner',
      gitRepoName: 'repository',
    );

    expect(project.isGitHubProject, isTrue);
  });

  test('workspace project keeps its Supabase owner identity', () {
    final project = Project.fromWorkspaceRow({
      'id': 'project-1',
      'user_id': 'user-a',
      'name': 'My repository',
      'description': 'Safe workspace copy',
      'git_repo_url': 'https://github.com/octocat/hello-world',
      'git_branch': 'main',
      'git_owner': 'octocat',
      'git_repo_name': 'hello-world',
    });

    expect(project.ownerId, 'user-a');
    expect(project.isGitHubProject, isTrue);
  });
}
