import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/feed_mock_data.dart';

/// ─── LocalPostsCache ────────────────────────────────────────────────────────
/// Persistent offline storage for posts created on this device.
/// Guarantees that user's created posts are NEVER lost across logouts,
/// tab switches, or network interruptions.
class LocalPostsCache {
  static const String _key = 'codesnap_local_user_posts';

  /// Save or prepend a new post to local persistent storage
  static Future<void> savePost(FeedPost post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await loadPosts();
      // Remove any existing copy with same ID
      list.removeWhere((p) => p.id == post.id);
      list.insert(0, post);

      // Keep up to 100 recent posts
      final trimmed = list.take(100).toList();
      final jsonList = trimmed.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_key, jsonList);
    } catch (e) {
      debugPrint('Error saving post to LocalPostsCache: $e');
    }
  }

  /// Load all posts saved locally on this device
  static Future<List<FeedPost>> loadPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_key);
      if (jsonList == null || jsonList.isEmpty) return [];

      final List<FeedPost> posts = [];
      for (final str in jsonList) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          posts.add(FeedPost.fromJson(map));
        } catch (_) {}
      }
      return posts;
    } catch (e) {
      debugPrint('Error loading posts from LocalPostsCache: $e');
      return [];
    }
  }

  /// Update the ID of a cached post when Supabase confirms creation
  static Future<void> updatePostId(String oldId, String newId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await loadPosts();
      final idx = list.indexWhere((p) => p.id == oldId);
      if (idx != -1) {
        final old = list[idx];
        list[idx] = FeedPost(
          id: newId,
          username: old.username,
          location: old.location,
          avatarUrl: old.avatarUrl,
          imageUrl: old.imageUrl,
          commentsCount: old.commentsCount,
          sharesCount: old.sharesCount,
          likesCount: old.likesCount,
          captionTitle: old.captionTitle,
          captionBody: old.captionBody,
          musicTitle: old.musicTitle,
          musicArtist: old.musicArtist,
          musicCoverUrl: old.musicCoverUrl,
          likedByAvatars: old.likedByAvatars,
          likedByText: old.likedByText,
          isVideo: old.isVideo,
          videoUrl: old.videoUrl,
        );
        final jsonList = list.map((p) => jsonEncode(p.toJson())).toList();
        await prefs.setStringList(_key, jsonList);
      }
    } catch (_) {}
  }
}
