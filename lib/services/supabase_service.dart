import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ─── SupabaseService ────────────────────────────────────────────────────────
/// Central client & authentication gateway for CodeSnap (Bug).
/// Database: PostgreSQL on Supabase (Tokyo region: ap-northeast-1)
class SupabaseService {
  static const String supabaseUrl = 'https://ztthiindnqvhdolqrano.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_-TMkYWMqCEMAWadmd1N9Kw_d6afPiII';

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Initialize Supabase client
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.accessToken.length > 16 * 1024) {
        debugPrint(
          'Supabase session was cleared because its token exceeded the safe header size.',
        );
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      }
      _initialized = true;
      debugPrint('⚡ Supabase successfully connected to: $supabaseUrl');
    } catch (e) {
      // Initialization failures must not be silently ignored: otherwise the
      // login screen loads with an unusable client and misleading network errors.
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
  }

  /// Direct Supabase client instance
  static SupabaseClient get client {
    if (!_initialized) {
      return Supabase.instance.client;
    }
    return Supabase.instance.client;
  }

  /// Current authenticated user
  static User? get currentUser => _initialized ? client.auth.currentUser : null;

  /// Current user ID
  static String? get currentUserId => currentUser?.id;

  /// Check if user is currently logged in
  static bool get isAuthenticated => currentUser != null;

  // ── Database Table Names ──────────────────────────────────────────────────
  static const String tableProfiles = 'profiles';
  static const String tablePosts = 'posts';
  static const String tablePostLikes = 'post_likes';
  static const String tableComments = 'comments';
  static const String tableStories = 'stories';
  static const String tableFollowers = 'followers';
  static const String tableConversations = 'conversations';
  static const String tableMessages = 'messages';
  static const String tableNotifications = 'notifications';
  static const String tableWorkspaceProjects = 'workspace_projects';
  static const String tableWorkspaceFiles = 'workspace_files';
  static const String bucketPostMedia = 'post-media';
}
