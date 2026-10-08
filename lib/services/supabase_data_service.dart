import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// ─── SupabaseDataService ───────────────────────────────────────────────────
/// High-level production service for Auth, Feed, Stories, Social, Chat, & Workspace
class SupabaseDataService {
  static SupabaseClient get _client => SupabaseService.client;

  // ═══════════════════════════════════════════════════════════════════════════
  //  1. AUTHENTICATION & PROFILES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Register new user with email, password & username
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'username': username.trim().toLowerCase(),
        'full_name': fullName ?? username,
      },
    );
    return res;
  }

  /// Sign in existing user
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out current user
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current user profile from `profiles` table
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    Map<String, dynamic>? data;
    try {
      data = await _client
          .from(SupabaseService.tableProfiles)
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Supabase profiles select exception: $e');
    }

    final meta = user.userMetadata ?? {};
    return {
      'id': user.id,
      'email': user.email ?? '',
      'full_name': data?['full_name'] ??
          meta['full_name'] ??
          user.email?.split('@').first ??
          'Developer',
      'username': data?['username'] ??
          meta['username'] ??
          user.email?.split('@').first ??
          'dev',
      'avatar_url': data?['avatar_url'] ?? meta['avatar_url'] ?? '',
      'headline': data?['headline'] ?? meta['headline'] ?? '',
      'bio': data?['bio'] ?? meta['bio'] ?? '',
      'department': data?['department'] ?? meta['department'] ?? '',
      'location': data?['location'] ?? meta['location'] ?? '',
      'skills': data?['skills'] ?? meta['skills'] ?? <dynamic>[],
      'github_handle': data?['github_handle'] ?? meta['github_handle'] ?? '',
    };
  }

  /// Fetch profile by email or user ID from `profiles` table
  static Future<Map<String, dynamic>?> getProfileByIdOrEmail(
      {String? userId, String? email}) async {
    try {
      if (userId != null && userId.isNotEmpty && _isUuid(userId)) {
        try {
          final data = await _client
              .from(SupabaseService.tableProfiles)
              .select()
              .eq('id', userId)
              .maybeSingle()
              .timeout(const Duration(seconds: 3));
          if (data != null) return data;
        } catch (_) {}
      }
      if (email != null && email.isNotEmpty) {
        final uname = email.split('@').first.toLowerCase();
        try {
          final data = await _client
              .from(SupabaseService.tableProfiles)
              .select()
              .eq('username', uname)
              .maybeSingle()
              .timeout(const Duration(seconds: 3));
          if (data != null) return data;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error getting profile by id/email: $e');
    }
    return null;
  }

  /// Update user profile details in both Supabase `profiles` table and Supabase Auth metadata
  static Future<String?> updateProfile({
    String? userId,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? headline,
    String? department,
    String? location,
    String? githubHandle,
    List<String>? skills,
  }) async {
    final user = _client.auth.currentUser;
    // Never write to another user's profile from a client session.
    if (user == null || (userId != null && userId != user.id)) {
      throw StateError('An authenticated matching user is required.');
    }
    final targetId = user.id;

    String? persistedAvatar = avatarUrl;
    if (avatarUrl != null &&
        (avatarUrl.startsWith('data:') || avatarUrl.startsWith('blob:'))) {
      persistedAvatar = await _persistMediaValue(
        avatarUrl,
        userId: targetId,
        recordId: 'avatar',
      );
      if (persistedAvatar == null) {
        debugPrint('Supabase profile update skipped an invalid avatar value.');
      }
    }

    // 1. Persist to Supabase Auth metadata (if auth session exists)
    if (user != null) {
      final metaUpdates = <String, dynamic>{};
      if (fullName != null) metaUpdates['full_name'] = fullName;
      if (bio != null) metaUpdates['bio'] = bio;
      if (persistedAvatar != null) {
        metaUpdates['avatar_url'] = persistedAvatar;
      }
      if (headline != null) metaUpdates['headline'] = headline;
      if (department != null) metaUpdates['department'] = department;
      if (location != null) metaUpdates['location'] = location;
      if (githubHandle != null) metaUpdates['github_handle'] = githubHandle;
      if (skills != null) metaUpdates['skills'] = skills;

      if (metaUpdates.isNotEmpty) {
        try {
          await _client.auth.updateUser(UserAttributes(data: metaUpdates));
        } catch (e) {
          debugPrint('Supabase updateUser metadata error: $e');
        }
      }
    }

    // 2. Persist/upsert into `profiles` database table
    final tableUpdates = <String, dynamic>{
      'id': targetId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) tableUpdates['full_name'] = fullName;
    if (bio != null) tableUpdates['bio'] = bio;
    if (persistedAvatar != null) {
      tableUpdates['avatar_url'] = persistedAvatar;
    }
    if (headline != null) tableUpdates['headline'] = headline;
    if (department != null) tableUpdates['department'] = department;
    if (location != null) tableUpdates['location'] = location;
    if (githubHandle != null) tableUpdates['github_handle'] = githubHandle;
    if (skills != null) tableUpdates['skills'] = skills;

    // The auth.users trigger already creates profiles. A partial upsert
    // attempts an INSERT without the required username and returns HTTP 400.
    await _client
        .from(SupabaseService.tableProfiles)
        .update(tableUpdates)
        .eq('id', targetId);
    return persistedAvatar;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  2. POSTS & FEED
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch all posts ordered by newest first (joined with author profiles)
  static Future<List<Map<String, dynamic>>> fetchPosts({int limit = 40}) async {
    try {
      final data = await _client.from(SupabaseService.tablePosts).select('''
            id,
            user_id,
            title,
            description,
            code_snippet,
            code_language,
            tags,
            likes_count,
            comments_count,
            created_at,
            profiles (
              id,
              username,
              full_name,
              avatar_url
            )
          ''').order('created_at', ascending: false).limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint(
          'Error fetching posts with profile join: $e. Retrying flat query...');
      try {
        final flatPosts = await _client
            .from(SupabaseService.tablePosts)
            .select()
            .order('created_at', ascending: false)
            .limit(limit);

        final List<Map<String, dynamic>> result = [];
        final userIds = flatPosts
            .map((p) => p['user_id']?.toString())
            .where((id) => id != null && _isUuid(id!))
            .cast<String>()
            .toSet()
            .toList();

        Map<String, Map<String, dynamic>> profileMap = {};
        if (userIds.isNotEmpty) {
          try {
            final profilesData = await _client
                .from(SupabaseService.tableProfiles)
                .select()
                .filter('id', 'in', userIds)
                .timeout(const Duration(seconds: 3));
            for (final prof in (profilesData as List)) {
              if (prof['id'] != null) {
                profileMap[prof['id'].toString()] =
                    Map<String, dynamic>.from(prof as Map);
              }
            }
          } catch (_) {}
        }

        for (final p in flatPosts) {
          final copy = Map<String, dynamic>.from(p);
          final uid = copy['user_id']?.toString();
          if (uid != null && profileMap.containsKey(uid)) {
            copy['profiles'] = profileMap[uid];
          }
          result.add(copy);
        }
        return result;
      } catch (e2) {
        debugPrint('Flat posts query also failed: $e2');
        return [];
      }
    }
  }

  /// Fetch posts for a specific user
  /// Returns true if [s] looks like a UUID (Supabase auth IDs are UUIDs)
  static bool _isUuid(String s) {
    return RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false)
        .hasMatch(s);
  }

  /// Converts any string or non-UUID id deterministically to a valid standard UUID
  static String toValidUuid(String id) {
    if (_isUuid(id)) return id;
    final clean = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final seed = (clean + 'codesnapfallbackuuid0123456789abcdef').toLowerCase();
    final hexChars =
        seed.codeUnits.map((c) => (c % 16).toRadixString(16)).join();
    final h = hexChars.padRight(32, '0').substring(0, 32);
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-4${h.substring(13, 16)}-a${h.substring(17, 20)}-${h.substring(20, 32)}';
  }

  /// Fetch posts for a specific user
  static Future<List<Map<String, dynamic>>> fetchUserPosts(
      String userId) async {
    final validId = _isUuid(userId) ? userId : toValidUuid(userId);
    try {
      final data = await _client
          .from(SupabaseService.tablePosts)
          .select()
          .eq('user_id', validId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
      return [];
    }
  }

  /// Create a new post
  static Future<Map<String, dynamic>?> createPost({
    required String description,
    String? title,
    String? codeSnippet,
    String codeLanguage = 'dart',
    List<String> tags = const [],
    String? userId,
    String? authorUsername,
    String? authorFullName,
    String? authorAvatar,
    String? postId,
  }) async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null || authUid.isEmpty) {
      debugPrint(
          'Supabase createPost skipped: no authenticated Supabase session.');
      return null;
    }
    final uid = authUid;
    final resolvedPostId = postId != null && _isUuid(postId) ? postId : null;

    // The signup trigger owns profile creation. Upserting here can overwrite
    // the user's existing username or fail with a unique-key HTTP 400.
    final authorProfile = await _client
        .from(SupabaseService.tableProfiles)
        .select('id')
        .eq('id', uid)
        .maybeSingle();
    if (authorProfile == null) {
      debugPrint('Cannot post: authenticated user has no profile row.');
      return null;
    }

    try {
      final persistedSnippet = await _persistMediaValue(
        codeSnippet,
        userId: uid,
        recordId: resolvedPostId ??
            toValidUuid(
              '${DateTime.now().microsecondsSinceEpoch}-$uid',
            ),
      );
      if (codeSnippet != null &&
          (codeSnippet.startsWith('data:') ||
              codeSnippet.startsWith('blob:')) &&
          persistedSnippet == null) {
        return null;
      }

      final payload = <String, dynamic>{
        'user_id': uid,
        'title': title ?? 'Code Snippet',
        'description': description,
        'code_snippet': persistedSnippet,
        'code_language': codeLanguage,
        'tags': tags,
      };
      if (resolvedPostId != null) payload['id'] = resolvedPostId;

      final res = await _client
          .from(SupabaseService.tablePosts)
          .upsert(payload, onConflict: 'id')
          .select()
          .single();

      return res;
    } catch (e) {
      debugPrint('Supabase createPost error: $e');
      return null;
    }
  }

  /// Moves browser data URLs into Supabase Storage before a database row is
  /// written. HTTP URLs and ordinary code snippets are already durable and are
  /// returned unchanged.
  static Future<String?> _persistMediaValue(
    String? value, {
    required String userId,
    required String recordId,
  }) async {
    if (value == null || value.isEmpty) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('blob:')) {
      debugPrint('Supabase media upload failed: blob URLs are not durable.');
      return null;
    }
    if (!value.startsWith('data:')) return value;

    try {
      final comma = value.indexOf(',');
      if (comma <= 5) return null;
      final metadata = value.substring(5, comma);
      final mimeType = metadata.split(';').first;
      final isBase64 = metadata.split(';').contains('base64');
      final encoded = value.substring(comma + 1);
      final bytes = isBase64
          ? base64Decode(encoded)
          : Uint8List.fromList(utf8.encode(Uri.decodeComponent(encoded)));

      const maxUploadBytes = 25 * 1024 * 1024;
      if (bytes.lengthInBytes > maxUploadBytes) {
        debugPrint('Supabase media upload failed: file exceeds 25 MB.');
        return null;
      }

      final extension = switch (mimeType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/gif' => 'gif',
        'video/webm' => 'webm',
        'video/quicktime' => 'mov',
        'video/mp4' => 'mp4',
        _ => mimeType.startsWith('video/') ? 'mp4' : 'jpg',
      };
      final objectPath = '$userId/$recordId.$extension';
      await _client.storage.from(SupabaseService.bucketPostMedia).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              cacheControl: '31536000',
              upsert: true,
            ),
          );
      return _client.storage
          .from(SupabaseService.bucketPostMedia)
          .getPublicUrl(objectPath);
    } catch (e) {
      debugPrint('Supabase media upload error: $e');
      return null;
    }
  }

  /// Toggle like on post (inserts or deletes in `post_likes` table and updates `likes_count`)
  static Future<bool> togglePostLike(String postId, {String? userId}) async {
    final uid = userId ?? _client.auth.currentUser?.id;
    if (uid == null || !_isUuid(uid) || !_isUuid(postId)) return false;

    try {
      // Check if like exists
      final existing = await _client
          .from(SupabaseService.tablePostLikes)
          .select()
          .eq('post_id', postId)
          .eq('user_id', uid)
          .maybeSingle();

      bool isNowLiked = false;
      if (existing != null) {
        // Unlike
        await _client
            .from(SupabaseService.tablePostLikes)
            .delete()
            .eq('post_id', postId)
            .eq('user_id', uid);
        isNowLiked = false;
      } else {
        // Like
        await _client.from(SupabaseService.tablePostLikes).insert({
          'post_id': postId,
          'user_id': uid,
        });
        isNowLiked = true;
      }

      // Update real likes_count in posts table so every client gets the exact real count
      try {
        final allLikes = await _client
            .from(SupabaseService.tablePostLikes)
            .select('id')
            .eq('post_id', postId);
        final realCount = (allLikes as List).length;
        await _client
            .from(SupabaseService.tablePosts)
            .update({'likes_count': realCount}).eq('id', postId);
      } catch (_) {}

      return isNowLiked;
    } catch (e) {
      debugPrint('Supabase togglePostLike error: $e');
      return false;
    }
  }

  /// Fetch IDs of posts liked by a specific user
  static Future<Set<String>> fetchUserLikedPostIds({String? userId}) async {
    final uid = userId ?? _client.auth.currentUser?.id;
    if (uid == null || !_isUuid(uid)) return {};

    try {
      final res = await _client
          .from(SupabaseService.tablePostLikes)
          .select('post_id')
          .eq('user_id', uid);

      return (res as List).map((r) => r['post_id'].toString()).toSet();
    } catch (e) {
      debugPrint('Supabase fetchUserLikedPostIds error: $e');
      return {};
    }
  }

  /// Add a comment to a post
  static Future<Map<String, dynamic>?> addComment({
    required String postId,
    required String content,
    String? userId,
  }) async {
    final uid = userId ?? _client.auth.currentUser?.id;
    if (uid == null) return null;

    try {
      final res = await _client
          .from(SupabaseService.tableComments)
          .insert({
            'post_id': postId,
            'user_id': uid,
            'content': content.trim(),
          })
          .select()
          .single();

      return res;
    } catch (e) {
      debugPrint('Supabase addComment error: $e');
      return null;
    }
  }

  /// Fetch comments for a post
  static Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    // Skip if postId is a local temp ID (not a UUID)
    if (!_isUuid(postId)) return [];

    try {
      final data = await _client.from(SupabaseService.tableComments).select('''
            id,
            post_id,
            user_id,
            content,
            created_at,
            profiles (
              username,
              full_name,
              avatar_url
            )
          ''').eq('post_id', postId).order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint(
          'Error fetching comments with join: $e. Retrying flat query...');
      try {
        final flatComments = await _client
            .from(SupabaseService.tableComments)
            .select()
            .eq('post_id', postId)
            .order('created_at', ascending: true);

        final List<Map<String, dynamic>> result = [];
        for (final c in flatComments) {
          final copy = Map<String, dynamic>.from(c);
          final uid = copy['user_id']?.toString();
          if (uid != null && _isUuid(uid)) {
            final prof = await getProfileByIdOrEmail(userId: uid);
            copy['profiles'] = prof;
          }
          result.add(copy);
        }
        return result;
      } catch (e2) {
        debugPrint('Flat comments query also failed: $e2');
        return [];
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  3. 24-HOUR STORIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch stories active within the last 24 hours
  static Future<List<Map<String, dynamic>>> fetchActiveStories() async {
    try {
      final yesterday = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 24))
          .toIso8601String();
      final data = await _client
          .from(SupabaseService.tableStories)
          .select('''
            id,
            user_id,
            title,
            code_snippet,
            code_language,
            media_url,
            views_count,
            created_at,
            profiles (
              username,
              full_name,
              avatar_url
            )
          ''')
          .gte('created_at', yesterday)
          .order('created_at', ascending: false)
          .limit(10)
          .timeout(const Duration(seconds: 3));

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Supabase active stories query note: $e');
      return [];
    }
  }

  /// Post a new 24h story
  static Future<bool> createStory({
    required String title,
    String? codeSnippet,
    String codeLanguage = 'dart',
    String? mediaUrl,
    String? userId,
    String? authorUsername,
    String? authorFullName,
    String? authorAvatar,
    String? storyId,
  }) async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null || authUid.isEmpty) {
      debugPrint(
          'Supabase createStory skipped: no authenticated Supabase session.');
      return false;
    }
    final uid = authUid;
    final resolvedStoryId = storyId != null && _isUuid(storyId)
        ? storyId
        : toValidUuid('${DateTime.now().microsecondsSinceEpoch}-$uid-story');

    // Ensure author profile exists in profiles table
    try {
      await _client.from(SupabaseService.tableProfiles).upsert({
        'id': uid,
        'username': authorUsername ?? 'developer',
        'full_name': authorFullName ?? 'Developer',
        'avatar_url': authorAvatar ?? '',
      });
    } catch (_) {}

    try {
      final persistedMedia = await _persistMediaValue(
        mediaUrl,
        userId: uid,
        recordId: resolvedStoryId,
      );
      if (mediaUrl != null &&
          (mediaUrl.startsWith('data:') || mediaUrl.startsWith('blob:')) &&
          persistedMedia == null) {
        return false;
      }

      await _client.from(SupabaseService.tableStories).upsert({
        'id': resolvedStoryId,
        'user_id': uid,
        'title': title,
        'code_snippet': codeSnippet,
        'code_language': codeLanguage,
        'media_url': persistedMedia,
      }, onConflict: 'id');
      return true;
    } catch (e) {
      debugPrint('Supabase createStory error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  4. FOLLOWERS & SOCIAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch all registered developers
  static Future<List<Map<String, dynamic>>> fetchDevelopers(
      {int limit = 50}) async {
    try {
      final data = await _client
          .from(SupabaseService.tableProfiles)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching developers: $e');
      return [];
    }
  }

  /// Toggle follow/unfollow for another developer
  static Future<bool> toggleFollow(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null || user.id == targetUserId) return false;

    final existing = await _client
        .from(SupabaseService.tableFollowers)
        .select()
        .eq('follower_id', user.id)
        .eq('following_id', targetUserId)
        .maybeSingle();

    if (existing != null) {
      // Unfollow
      await _client
          .from(SupabaseService.tableFollowers)
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId);
      return false;
    } else {
      // Follow
      await _client.from(SupabaseService.tableFollowers).insert({
        'follower_id': user.id,
        'following_id': targetUserId,
      });
      return true;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  5. CHAT & REALTIME MESSAGING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send a message with optional code snippet
  static Future<void> sendMessage({
    required String conversationId,
    required String text,
    String? codeSnippet,
    String? codeLanguage,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from(SupabaseService.tableMessages).insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'text': text,
      'code_snippet': codeSnippet,
      'code_language': codeLanguage,
    });
  }

  /// Real-time stream of messages for a conversation
  static Stream<List<Map<String, dynamic>>> streamMessages(
      String conversationId) {
    return _client
        .from(SupabaseService.tableMessages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  6. NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch notifications for current user
  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _client
          .from(SupabaseService.tableNotifications)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from(SupabaseService.tableNotifications)
        .update({'is_read': true}).eq('id', notificationId);
  }

  /// Delete / dismiss notification (swipe to dismiss)
  static Future<void> deleteNotification(String notificationId) async {
    await _client
        .from(SupabaseService.tableNotifications)
        .delete()
        .eq('id', notificationId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  7. WORKSPACE CLOUD SYNC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save or update a project and its file tree in the cloud
  static Future<void> saveWorkspaceProject({
    required String projectName,
    required Map<String, String> files,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // 1. Get or create project
    final existing = await _client
        .from(SupabaseService.tableWorkspaceProjects)
        .select('id')
        .eq('user_id', user.id)
        .eq('name', projectName)
        .maybeSingle();

    final String projectId;
    if (existing != null) {
      projectId = existing['id'] as String;
      await _client.from(SupabaseService.tableWorkspaceProjects).update(
          {'updated_at': DateTime.now().toIso8601String()}).eq('id', projectId);
    } else {
      final created = await _client
          .from(SupabaseService.tableWorkspaceProjects)
          .insert({
            'user_id': user.id,
            'name': projectName,
          })
          .select('id')
          .single();
      projectId = created['id'] as String;
    }

    // 2. Upsert files
    for (final entry in files.entries) {
      await _client.from(SupabaseService.tableWorkspaceFiles).upsert({
        'project_id': projectId,
        'path': entry.key,
        'content': entry.value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
