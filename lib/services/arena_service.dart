import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import 'supabase_service.dart';
import 'upload_status_service.dart';

/// Database gateway for Arena. No event, team, vote, submission, or bookmark
/// state is kept as mock/local data.
class ArenaService {
  ArenaService._();

  static SupabaseClient get _client => SupabaseService.client;
  static String? get _uid => _client.auth.currentUser?.id;

  static Future<List<Task>> fetchEvents() async {
    try {
      final events = List<Map<String, dynamic>>.from(
        await _client
            .from('arena_events')
            .select()
            .order('created_at', ascending: false)
            .timeout(const Duration(seconds: 8)),
      );
      if (events.isEmpty) return [];

      final eventIds = events.map((row) => row['id'].toString()).toList();
      final ownerIds =
          events.map((row) => row['owner_id'].toString()).toSet().toList();
      final teams = List<Map<String, dynamic>>.from(
        await _client
            .from('arena_teams')
            .select()
            .inFilter('event_id', eventIds)
            .order('created_at', ascending: true)
            .timeout(const Duration(seconds: 8)),
      );
      final profiles = List<Map<String, dynamic>>.from(
        await _client
            .from(SupabaseService.tableProfiles)
            .select('id, username, full_name, avatar_url')
            .inFilter('id', ownerIds)
            .timeout(const Duration(seconds: 8)),
      );
      final profileById = {
        for (final profile in profiles) profile['id'].toString(): profile,
      };

      final uid = _uid;
      final bookmarkedIds = <String>{};
      final votedTeamByEvent = <String, String>{};
      if (uid != null) {
        final results = await Future.wait([
          _client.from('arena_bookmarks').select('event_id').eq('user_id', uid),
          _client
              .from('arena_votes')
              .select('event_id, team_id')
              .eq('voter_id', uid),
        ]);
        for (final row in List<Map<String, dynamic>>.from(results[0])) {
          bookmarkedIds.add(row['event_id'].toString());
        }
        for (final row in List<Map<String, dynamic>>.from(results[1])) {
          votedTeamByEvent[row['event_id'].toString()] =
              row['team_id'].toString();
        }
      }

      final teamsByEvent = <String, List<TeamShowdown>>{};
      for (final row in teams) {
        final eventId = row['event_id'].toString();
        teamsByEvent
            .putIfAbsent(eventId, () => <TeamShowdown>[])
            .add(TeamShowdown.fromJson(row));
      }

      return events.map((row) {
        final id = row['id'].toString();
        final eventTeams = teamsByEvent[id] ?? <TeamShowdown>[];
        final ownerId = row['owner_id']?.toString() ?? '';
        final owner = profileById[ownerId];
        String? currentUserTeamId;
        if (uid != null) {
          for (final team in eventTeams) {
            if (team.ownerId == uid) {
              currentUserTeamId = team.id;
              break;
            }
          }
        }
        return Task(
          id: id,
          title: row['title']?.toString() ?? 'Arena event',
          description: row['description']?.toString() ?? '',
          course: row['course']?.toString() ?? 'Community',
          branch: row['branch']?.toString() ?? 'Global',
          section: row['section']?.toString() ?? 'A',
          year: row['year']?.toString() ?? '',
          deadline: row['deadline']?.toString() ?? '',
          createdAt: row['created_at']?.toString() ?? '',
          ownerId: ownerId,
          ownerName: owner?['full_name']?.toString().trim().isNotEmpty == true
              ? owner!['full_name'].toString()
              : owner?['username']?.toString() ?? 'Arena host',
          ownerAvatarUrl: owner?['avatar_url']?.toString() ?? '',
          submissionCount: (row['submission_count'] as num?)?.toInt() ?? 0,
          starterCode: row['starter_code']?.toString(),
          prizePool: row['prize_pool']?.toString() ?? '₹10,000',
          eventType: row['event_type']?.toString() ?? 'Hackathon',
          status: row['status']?.toString() ?? 'LIVE',
          tags: (row['tags'] as List<dynamic>?)
                  ?.map((value) => value.toString())
                  .toList() ??
              const [],
          teamsCount:
              (row['teams_count'] as num?)?.toInt() ?? eventTeams.length,
          totalVotes: eventTeams.fold<int>(0, (sum, team) => sum + team.votes),
          teams: eventTeams,
          isBookmarked: bookmarkedIds.contains(id),
          currentUserTeamId: currentUserTeamId,
        );
      }).toList();
    } catch (error, stackTrace) {
      debugPrint('Arena fetch failed: $error\n$stackTrace');
      rethrow;
    }
  }

  static Future<Task?> fetchEvent(String eventId) async {
    final events = await fetchEvents();
    for (final event in events) {
      if (event.id == eventId) return event;
    }
    return null;
  }

  static Future<void> createEvent({
    required String title,
    required String description,
    required String prizePool,
    required String eventType,
    required List<String> tags,
    required DateTime deadline,
  }) async {
    await _trackedUpload('Publishing Arena event', () async {
      final uid = _requireUser();
      await _client.from('arena_events').insert({
        'owner_id': uid,
        'title': title.trim(),
        'description': description.trim(),
        'deadline': deadline.toUtc().toIso8601String(),
        'prize_pool': prizePool.trim().isEmpty ? '₹10,000' : prizePool.trim(),
        'event_type': eventType,
        'status': 'LIVE',
        'tags': tags,
      });
    });
  }

  static Future<void> registerTeam({
    required String eventId,
    required String teamName,
    required String projectTitle,
    required List<String> memberHandles,
  }) async {
    await _trackedUpload('Registering Arena team', () async {
      final uid = _requireUser();
      final profile = await _client
          .from(SupabaseService.tableProfiles)
          .select('avatar_url')
          .eq('id', uid)
          .maybeSingle();
      final avatar = profile?['avatar_url']?.toString() ?? '';
      await _client.from('arena_teams').insert({
        'event_id': eventId,
        'owner_id': uid,
        'team_name': teamName.trim(),
        'project_title': projectTitle.trim().isEmpty
            ? 'New challenger'
            : projectTitle.trim(),
        'growth_update': 'Registered in the Arena.',
        'member_handles': memberHandles,
        'member_avatars': avatar.isEmpty ? <String>[] : [avatar],
      });
    });
  }

  static Future<void> submitProject({
    required String eventId,
    required String repoUrl,
    required String demoUrl,
    required String summary,
    String? teamId,
  }) async {
    await _trackedUpload('Submitting Arena project', () async {
      final uid = _requireUser();
      await _client.from('arena_submissions').upsert({
        'event_id': eventId,
        'team_id': teamId,
        'user_id': uid,
        'repo_url': repoUrl.trim(),
        'demo_url': demoUrl.trim().isEmpty ? null : demoUrl.trim(),
        'summary': summary.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'event_id,user_id');

      if (teamId != null) {
        await _client
            .from('arena_teams')
            .update({
              'repo_url': repoUrl.trim(),
              'demo_url': demoUrl.trim().isEmpty ? null : demoUrl.trim(),
              'growth_update': summary.trim().isEmpty
                  ? 'Project submitted for judging.'
                  : summary.trim(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', teamId)
            .eq('owner_id', uid);
      }
    });
  }

  static Future<void> castVote({
    required String eventId,
    required String teamId,
  }) async {
    final uid = _requireUser();
    await _client.from('arena_votes').upsert({
      'event_id': eventId,
      'team_id': teamId,
      'voter_id': uid,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'event_id,voter_id');
  }

  static Future<bool> toggleBookmark({
    required String eventId,
    required bool currentlyBookmarked,
  }) async {
    final uid = _requireUser();
    if (currentlyBookmarked) {
      await _client
          .from('arena_bookmarks')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', uid);
      return false;
    }
    await _client.from('arena_bookmarks').insert({
      'event_id': eventId,
      'user_id': uid,
    });
    return true;
  }

  static String _requireUser() {
    final uid = _uid;
    if (uid == null) {
      throw const AuthException('Sign in to use Arena.');
    }
    return uid;
  }

  static Future<void> _trackedUpload(
    String label,
    Future<void> Function() operation,
  ) async {
    UploadStatusService.instance.start(label: label);
    try {
      await operation();
      UploadStatusService.instance.succeed(label: '$label complete');
    } catch (_) {
      UploadStatusService.instance.fail(label: '$label failed');
      rethrow;
    }
  }
}
