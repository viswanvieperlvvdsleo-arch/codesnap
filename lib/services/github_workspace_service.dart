import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class GitRepositoryRef {
  final String owner;
  final String name;

  const GitRepositoryRef({required this.owner, required this.name});

  String get fullName => '$owner/$name';
  String get url => 'https://github.com/$fullName';
}

class GitRepositoryInfo {
  final String owner;
  final String name;
  final String url;
  final String defaultBranch;
  final String? description;
  final bool isPrivate;

  const GitRepositoryInfo({
    required this.owner,
    required this.name,
    required this.url,
    required this.defaultBranch,
    required this.description,
    required this.isPrivate,
  });

  factory GitRepositoryInfo.fromJson(Map<String, dynamic> json) {
    return GitRepositoryInfo(
      owner: json['owner'].toString(),
      name: json['name'].toString(),
      url: json['url'].toString(),
      defaultBranch: json['default_branch']?.toString() ?? 'main',
      description: json['description']?.toString(),
      isPrivate: json['private'] == true,
    );
  }
}

class GitTreeEntry {
  final String path;
  final String type;
  final String sha;
  final int size;

  const GitTreeEntry({
    required this.path,
    required this.type,
    required this.sha,
    required this.size,
  });

  bool get isDirectory => type == 'tree';

  factory GitTreeEntry.fromJson(Map<String, dynamic> json) {
    return GitTreeEntry(
      path: json['path'].toString(),
      type: json['type'].toString(),
      sha: json['sha'].toString(),
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class GitLoadedRepository {
  final Map<String, String> files;
  final Map<String, String> blobShas;
  final List<String> skippedFiles;

  const GitLoadedRepository({
    required this.files,
    required this.blobShas,
    required this.skippedFiles,
  });
}

class GitCommitResult {
  final String commitSha;
  final String blobSha;
  final String htmlUrl;

  const GitCommitResult({
    required this.commitSha,
    required this.blobSha,
    required this.htmlUrl,
  });
}

class GithubWorkspaceService {
  GithubWorkspaceService._();

  static String? _sessionToken;
  static SupabaseClient get _client => SupabaseService.client;

  /// A fine-grained token is intentionally held in memory only. It is never
  /// persisted in Supabase, local storage, logs, or source code.
  static void setSessionToken(String token) {
    final trimmed = token.trim();
    _sessionToken = trimmed.isEmpty ? null : trimmed;
  }

  static void clearSessionToken() => _sessionToken = null;

  static String? get _credential {
    final oauthToken = _client.auth.currentSession?.providerToken?.trim();
    if (oauthToken != null && oauthToken.isNotEmpty) return oauthToken;
    return _sessionToken;
  }

  static bool get hasWriteCredential => _credential?.isNotEmpty == true;

  static GitRepositoryRef parseRepositoryUrl(String input) {
    final trimmed = input.trim();
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri == null || uri.host.toLowerCase() != 'github.com') {
      throw const FormatException('Enter a valid github.com repository URL.');
    }
    final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (parts.length < 2) {
      throw const FormatException(
          'GitHub URL must include an owner and repository.');
    }
    final owner = parts[0];
    final name = parts[1].replaceFirst(RegExp(r'\.git$'), '');
    final validPart = RegExp(r'^[A-Za-z0-9_.-]+$');
    if (!validPart.hasMatch(owner) || !validPart.hasMatch(name)) {
      throw const FormatException(
          'The GitHub owner or repository name is invalid.');
    }
    return GitRepositoryRef(owner: owner, name: name);
  }

  static Future<Map<String, dynamic>> _invoke(
    String operation,
    Map<String, dynamic> body, {
    bool requireCredential = false,
  }) async {
    if (!SupabaseService.isAuthenticated) {
      throw StateError('Sign in before linking a GitHub repository.');
    }
    final credential = _credential;
    if (requireCredential && (credential == null || credential.isEmpty)) {
      throw StateError('A GitHub token is required to push this commit.');
    }
    final response = await _client.functions.invoke(
      'github-workspace',
      body: {
        'operation': operation,
        ...body,
        if (credential != null && credential.isNotEmpty)
          'github_token': credential,
      },
    );
    if (response.data is! Map) {
      throw StateError('GitHub returned an unexpected response.');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) throw StateError(data['error'].toString());
    return data;
  }

  static Future<GitRepositoryInfo> inspectRepository(String repoUrl) async {
    final ref = parseRepositoryUrl(repoUrl);
    final data = await _invoke('repository', {
      'owner': ref.owner,
      'repo': ref.name,
    });
    return GitRepositoryInfo.fromJson(data);
  }

  static Future<List<GitTreeEntry>> fetchTree({
    required String owner,
    required String repo,
    required String branch,
  }) async {
    final data = await _invoke('tree', {
      'owner': owner,
      'repo': repo,
      'branch': branch,
    });
    final entries = data['entries'] as List? ?? const [];
    return entries
        .whereType<Map>()
        .map((entry) => GitTreeEntry.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  static Future<GitLoadedRepository> loadRepository({
    required String owner,
    required String repo,
    required String branch,
  }) async {
    final data = await _invoke('load', {
      'owner': owner,
      'repo': repo,
      'branch': branch,
    });
    final rawFiles =
        Map<String, dynamic>.from(data['files'] as Map? ?? const {});
    final rawShas =
        Map<String, dynamic>.from(data['blob_shas'] as Map? ?? const {});
    return GitLoadedRepository(
      files: rawFiles.map((key, value) => MapEntry(key, value.toString())),
      blobShas: rawShas.map((key, value) => MapEntry(key, value.toString())),
      skippedFiles:
          List<String>.from(data['skipped_files'] as List? ?? const []),
    );
  }

  static Future<GitCommitResult> commitFile({
    required String sourceProjectId,
    required bool personalCopy,
    required String owner,
    required String repo,
    required String branch,
    required String path,
    required String content,
    required String message,
    String? sha,
  }) async {
    final data = await _invoke(
      'commit_file',
      {
        'owner': owner,
        'repo': repo,
        'branch': branch,
        'source_project_id': sourceProjectId,
        'personal_copy': personalCopy,
        'path': path,
        'content': content,
        'message': message,
        if (sha != null && sha.isNotEmpty) 'sha': sha,
      },
      requireCredential: true,
    );
    return GitCommitResult(
      commitSha: data['commit_sha']?.toString() ?? '',
      blobSha: data['blob_sha']?.toString() ?? '',
      htmlUrl: data['html_url']?.toString() ?? '',
    );
  }
}
