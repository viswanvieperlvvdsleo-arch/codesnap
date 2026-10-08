import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/theme_provider.dart';
import '../utils/feed_mock_data.dart';
import '../utils/app_animations.dart';
import '../widgets/morphing_capsule.dart';
import '../widgets/elastic_scroll_view.dart';
import '../widgets/swipe_action_bar.dart';
import '../widgets/interactive_bottom_cards.dart';
import '../widgets/floating_action_bar.dart' as quick_actions;
import '../widgets/spring_button.dart';
import '../screens/story_viewer_screen.dart';
import '../screens/full_screen_reels_screen.dart';
import '../screens/user_profile_detail_screen.dart';
import '../utils/mock_data.dart';
import '../services/storage_picker.dart';
import '../services/saved_posts_manager.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'chat_screen.dart';
import 'create_post_studio_screen.dart';
import '../services/supabase_data_service.dart';
import '../services/local_posts_cache.dart';
import '../services/supabase_service.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<FeedStory> _stories = [];
  final List<FeedStoryItem> _myStoryItems = [];
  List<FeedPost> _posts = [];
  bool _isLoadingFeed = true;
  List<PickedPost> get _pickedPosts => _posts
      .take(6)
      .map((p) => PickedPost(
            id: p.id,
            imageUrl: p.imageUrl,
            avatarUrl: p.avatarUrl,
            tag: p.captionTitle,
            postsCount: '${p.likesCount} likes',
          ))
      .toList();
  final ScrollController _scrollController = ScrollController();

  int _activeFilterIndex = 0;
  final List<String> _filters = [
    'For you',
    'Following',
    'Close Friends',
    'Photography',
  ];

  final Set<String> _likedPosts = {};
  final Set<String> _savedPosts = {};
  final Set<String> _pausedVideoPostIds = {};
  final Set<String> _mutedVideoPostIds = {};
  String? _activeActionPostId;
  Offset _actionBarPosition = Offset.zero;
  Offset _actionTouchPosition = Offset.zero;
  int _activeActionIndex = 2;
  double _activeActionBarWidth = 0;
  String? _coveredPostId;
  bool _coveredPostShowsComments = false;

  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0.0);

  // Per-post animation controllers for staggered entrance
  List<AnimationController> _postControllers = [];
  List<Animation<double>> _postFades = [];
  List<Animation<Offset>> _postSlides = [];

  // Filter chip spring controllers
  late List<AnimationController> _filterControllers;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      _scrollNotifier.value = _scrollController.offset;
    });

    // Post staggered entrance animations
    _postControllers = List.generate(
      _posts.length,
      (i) => AnimationController(
        vsync: this,
        duration: AppAnimations.expressive,
      ),
    );
    _postFades = _postControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _postSlides = _postControllers
        .map((c) =>
            Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: c, curve: AppAnimations.expressiveEntrance)))
        .toList();

    // Filter spring controllers
    _filterControllers = List.generate(
      _filters.length,
      (i) => AnimationController(
        vsync: this,
        duration: AppAnimations.quick,
      ),
    );

    // Stagger post entrance
    _loadUserLikes();
    _reinitPostControllers();
    _loadSupabasePosts();
    _loadSupabaseStories();
  }

  Future<void> _loadUserLikes() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.currentUser?.id;
      if (uid != null) {
        final likedIds =
            await SupabaseDataService.fetchUserLikedPostIds(userId: uid);
        if (mounted) {
          setState(() {
            _likedPosts.addAll(likedIds);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user likes: $e');
    }
  }

  void _reinitPostControllers() {
    for (final c in _postControllers) {
      c.dispose();
    }
    _postControllers = List.generate(
      _posts.length,
      (i) => AnimationController(
        vsync: this,
        duration: AppAnimations.expressive,
      ),
    );
    _postFades = _postControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _postSlides = _postControllers
        .map((c) =>
            Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: c, curve: AppAnimations.expressiveEntrance)))
        .toList();
    _launchPostEntrance();
  }

  Future<void> _launchPostEntrance() async {
    for (int i = 0; i < _postControllers.length; i++) {
      await Future.delayed(AppAnimations.stagger(i, baseMs: 80));
      if (mounted) _postControllers[i].forward();
    }
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      // Re-trigger post entrance
      for (final c in _postControllers) {
        c.reset();
      }

      // Move viewed stories to the back
      setState(() {
        _stories.sort((a, b) {
          if (a.isViewed && !b.isViewed) return 1;
          if (!a.isViewed && b.isViewed) return -1;
          return 0;
        });
      });

      await _launchPostEntrance();
      await Future.wait([_loadSupabasePosts(), _loadSupabaseStories()]);
    }
  }

  Future<void> _loadSupabasePosts() async {
    try {
      // 1. Immediately display cached local posts
      final cachedPosts = await LocalPostsCache.loadPosts();
      if (mounted && cachedPosts.isNotEmpty) {
        setState(() {
          final Set<String> existingIds = _posts.map((p) => p.id).toSet();
          final newCached =
              cachedPosts.where((cp) => !existingIds.contains(cp.id)).toList();
          if (newCached.isNotEmpty) {
            _posts = [...newCached, ..._posts];
          }
        });
      }

      await _syncPendingLocalPosts(cachedPosts);

      final supaPosts = await SupabaseDataService.fetchPosts(limit: 30);
      if (!mounted) return;
      if (supaPosts.isEmpty) {
        if (mounted) setState(() => _isLoadingFeed = false);
        return;
      }

      final List<FeedPost> remotePosts = [];
      for (final p in supaPosts) {
        final profile = p['profiles'] as Map<String, dynamic>?;
        final uname = profile?['username'] ?? 'developer';
        final avatar = profile?['avatar_url'] ??
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
        final snippet = p['code_snippet'] as String?;
        final desc = p['description'] as String? ?? '';
        final title = p['title'] as String? ?? 'Code Snippet';

        final imageUrl = (snippet != null &&
                (snippet.startsWith('http') ||
                    snippet.startsWith('data:image') ||
                    snippet.startsWith('blob:')))
            ? snippet
            : 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200';

        remotePosts.add(
          FeedPost(
            id: p['id'].toString(),
            username: uname,
            location: 'Tokyo Cloud',
            avatarUrl: avatar,
            imageUrl: imageUrl,
            commentsCount: (p['comments_count'] as num?)?.toInt() ?? 0,
            sharesCount: 0,
            likesCount: (p['likes_count'] as num?)?.toInt() ?? 0,
            captionTitle: title,
            captionBody: desc.isNotEmpty ? desc : (snippet ?? ''),
            musicTitle: 'Original Audio',
            musicArtist: uname,
            musicCoverUrl:
                'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150',
            likedByAvatars: [],
            likedByText: '${(p['likes_count'] as num?)?.toInt() ?? 0} likes',
          ),
        );
      }

      if (mounted) {
        setState(() {
          final Set<String> remoteIds = remotePosts.map((rp) => rp.id).toSet();
          final localUnsynced =
              _posts.where((lp) => !remoteIds.contains(lp.id)).toList();
          _posts = [...localUnsynced, ...remotePosts];
          _isLoadingFeed = false;
        });
        _reinitPostControllers();
      }
    } catch (e) {
      debugPrint('Error loading posts from Supabase: $e');
      if (mounted) setState(() => _isLoadingFeed = false);
    }
  }

  Future<void> _syncPendingLocalPosts(List<FeedPost> cachedPosts) async {
    if (!SupabaseService.isAuthenticated) return;

    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    for (final post in cachedPosts.where(
      (item) => !uuidPattern.hasMatch(item.id),
    )) {
      final remoteId = SupabaseDataService.toValidUuid(post.id);
      final result = await SupabaseDataService.createPost(
        postId: remoteId,
        title: post.captionTitle,
        description: post.captionBody,
        codeSnippet: post.imageUrl,
        authorUsername: post.username,
        authorFullName: post.username,
        authorAvatar: post.avatarUrl,
      );
      if (result == null || result['id'] == null) continue;

      final confirmedId = result['id'].toString();
      await LocalPostsCache.updatePostId(post.id, confirmedId);
      if (!mounted) return;
      setState(() {
        final index = _posts.indexWhere((item) => item.id == post.id);
        if (index != -1) {
          _posts[index] = _copyPostWithRemoteIdentity(
            post,
            id: confirmedId,
            imageUrl: result['code_snippet']?.toString(),
          );
        }
      });
    }
  }

  FeedPost _copyPostWithRemoteIdentity(
    FeedPost post, {
    required String id,
    String? imageUrl,
  }) {
    return FeedPost(
      id: id,
      username: post.username,
      location: post.location,
      avatarUrl: post.avatarUrl,
      imageUrl: imageUrl ?? post.imageUrl,
      commentsCount: post.commentsCount,
      sharesCount: post.sharesCount,
      likesCount: post.likesCount,
      captionTitle: post.captionTitle,
      captionBody: post.captionBody,
      musicTitle: post.musicTitle,
      musicArtist: post.musicArtist,
      musicCoverUrl: post.musicCoverUrl,
      likedByAvatars: post.likedByAvatars,
      likedByText: post.likedByText,
      isVideo: post.isVideo,
      videoUrl: post.videoUrl,
    );
  }

  Future<void> _loadSupabaseStories() async {
    FeedStory? myStoryCard;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.currentUser;
      final myAvatar = (currentUser?.avatarUrl?.isNotEmpty == true)
          ? currentUser!.avatarUrl
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';

      myStoryCard = FeedStory(
        id: 'my_story',
        username: 'Your Story',
        imageUrl: myAvatar,
        timeAgo: 'Add',
        isAddStory: true,
        items: _myStoryItems,
      );

      final supaStories = await SupabaseDataService.fetchActiveStories();
      if (!mounted) return;
      if (supaStories.isEmpty) {
        setState(() {
          _stories.clear();
          _stories.add(myStoryCard!);
        });
        return;
      }

      final List<FeedStory> remoteStories = [];
      for (final s in supaStories) {
        final profile = s['profiles'] as Map<String, dynamic>?;
        final uname = profile?['username'] ?? 'developer';
        final avatar = profile?['avatar_url'] ??
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
        final media = s['media_url'] as String? ??
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
        final title = s['title'] as String? ?? 'Story';

        remoteStories.add(
          FeedStory(
            id: s['id'].toString(),
            username: uname,
            imageUrl: avatar,
            timeAgo: 'Recent',
            items: [
              FeedStoryItem(
                id: 'item_${s['id']}',
                imageUrl: media,
                caption: title,
                time: 'Recent',
              ),
            ],
          ),
        );
      }

      if (mounted) {
        setState(() {
          _stories.clear();
          _stories.add(myStoryCard!);
          _stories.addAll(remoteStories);
        });
      }
    } catch (e) {
      debugPrint('Error loading stories from Supabase: $e');
      if (mounted && _stories.isEmpty && myStoryCard != null) {
        setState(() {
          _stories.add(myStoryCard!);
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollNotifier.dispose();
    _scrollController.dispose();
    for (final c in _postControllers) c.dispose();
    for (final c in _filterControllers) c.dispose();
    super.dispose();
  }

  void _triggerLike(FeedPost post) {
    final bool wasLiked = _likedPosts.contains(post.id);
    setState(() {
      if (wasLiked) {
        _likedPosts.remove(post.id);
        if (post.likesCount > 0) post.likesCount--;
      } else {
        _likedPosts.add(post.id);
        post.likesCount++;
      }
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.currentUser?.id;
      SupabaseDataService.togglePostLike(post.id, userId: uid);
    });
    if (!wasLiked) {
      MorphingCapsule.show(
        context,
        icon: LucideIcons.heart,
        label: 'Liked!',
        color: Colors.redAccent,
      );
    } else {
      MorphingCapsule.show(
        context,
        icon: LucideIcons.heartCrack,
        label: 'Unliked',
        color: Colors.white70,
      );
    }
  }

  void _openUserProfile(FeedPost post) {
    final user = User(
      id: post.id,
      name: post.username,
      email: '${post.username.toLowerCase()}@codesnap.com',
      avatarUrl: post.avatarUrl,
      section: post.username,
      headline: post.captionTitle,
      bio: post.captionBody,
      department: '',
      location: post.location,
      skills: const [],
    );
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          return UserProfileDetailScreen(user: user.toUserProfile());
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  void _likePost(FeedPost post) {
    _triggerLike(post);
    return;

    setState(() => _likedPosts.add(post.id));
    MorphingCapsule.show(
      context,
      icon: LucideIcons.heart,
      label: 'Liked!',
      color: Colors.redAccent,
    );
  }

  void _triggerSave(String postId) {
    final wasSaved = _savedPosts.contains(postId);
    setState(() {
      wasSaved ? _savedPosts.remove(postId) : _savedPosts.add(postId);
    });
    if (!wasSaved) {
      MorphingCapsule.show(
        context,
        icon: LucideIcons.bookmark,
        label: 'Saved',
        color: ThemeProvider.primaryGold,
      );
    }
  }

  void _startQuickActions(
    FeedPost post,
    LongPressStartDetails details,
    Size cardSize,
  ) {
    final barWidth = (cardSize.width - 20).clamp(280.0, 360.0);
    const barHeight = 70.0;
    final left = (details.localPosition.dx - barWidth / 2)
        .clamp(8.0, (cardSize.width - barWidth - 8).clamp(8.0, cardSize.width));
    final top = (details.localPosition.dy - barHeight - 22)
        .clamp(8.0, cardSize.height - barHeight - 8);

    setState(() {
      _activeActionPostId = post.id;
      _activeActionIndex = ((details.localPosition.dx - left) / (barWidth / 6))
          .floor()
          .clamp(0, 5);
      _activeActionBarWidth = barWidth;
      _actionBarPosition = Offset(left, top);
      _actionTouchPosition = details.localPosition;
    });
  }

  void _updateQuickActions(LongPressMoveUpdateDetails details) {
    final itemWidth = _activeActionBarWidth / 6;
    final index =
        ((details.localPosition.dx - _actionBarPosition.dx) / itemWidth)
            .floor();

    setState(() {
      _actionTouchPosition = details.localPosition;
      _activeActionIndex = index.clamp(0, 5);
    });
  }

  void _executeQuickAction(FeedPost post, int index) {
    setState(() => _activeActionPostId = null);
    if (index < 0 || index > 5) return;

    switch (index) {
      case 0: // Comment
        _showCommentsCover(post);
        break;
      case 1: // Share (connections search & share)
        _openShareToConnectionsSheet(post);
        break;
      case 2: // Like
        _likePost(post);
        break;
      case 3: // Save
        final nowSaved = SavedPostsManager.toggleSave(post);
        setState(() {
          if (nowSaved) {
            _savedPosts.add(post.id);
          } else {
            _savedPosts.remove(post.id);
          }
        });
        MorphingCapsule.show(
          context,
          icon:
              nowSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmarkMinus,
          label: nowSaved ? 'Saved to Saved List!' : 'Removed from Saved',
          color: const Color(0xFFFFD700),
        );
        break;
      case 4: // Download
        MorphingCapsule.show(
          context,
          icon: LucideIcons.download,
          label: 'Downloading to internal storage...',
          color: const Color(0xFF54C5F8),
        );
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            MorphingCapsule.show(
              context,
              icon: LucideIcons.checkCheck,
              label:
                  'Saved to internal gallery (${post.isVideo ? "video.mp4" : "image.jpg"})',
              color: const Color(0xFF10B981),
            );
          }
        });
        break;
      case 5: // More
        _showDescriptionCover(post);
        break;
    }
  }

  void _finishQuickActions(FeedPost post) {
    final index = _activeActionIndex;
    _executeQuickAction(post, index);
  }

  void _unusedOldFinishQuickActions(FeedPost post) {
    switch (_activeActionIndex) {
      case 0:
        _showCommentsCover(post);
        break;
      case 2:
        _likePost(post);
        break;
      case 3:
        _triggerSave(post.id);
        break;
      default:
        MorphingCapsule.show(
          context,
          icon: LucideIcons.sparkles,
          label: 'Action',
          color: ThemeProvider.primaryGold,
        );
    }

    setState(() => _activeActionPostId = null);
  }

  void _openPostLongPressOptions(FeedPost post) {
    return;
    final isLiked = _likedPosts.contains(post.id);
    final isSaved = SavedPostsManager.isSaved(post.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E17).withOpacity(0.96),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          post.imageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 44, height: 44, color: Colors.white12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.captionTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'by @${post.username} · ${post.location}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                  const SizedBox(height: 6),
                  _buildFeedOptionTile(
                    icon: isLiked ? LucideIcons.heartCrack : LucideIcons.heart,
                    iconColor: const Color(0xFFFF5252),
                    title: isLiked ? 'Unlike' : 'Like',
                    subtitle: isLiked
                        ? 'Remove like from this post'
                        : 'Send appreciation to @${post.username}',
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        if (isLiked) {
                          _likedPosts.remove(post.id);
                          MorphingCapsule.show(
                            context,
                            icon: LucideIcons.heartOff,
                            label: 'Unliked',
                            color: Colors.white70,
                          );
                        } else {
                          _likedPosts.add(post.id);
                          MorphingCapsule.show(
                            context,
                            icon: LucideIcons.heart,
                            label: 'Liked!',
                            color: const Color(0xFFFF5252),
                          );
                        }
                      });
                    },
                  ),
                  _buildFeedOptionTile(
                    icon: LucideIcons.share2,
                    iconColor: const Color(0xFF54C5F8),
                    title: 'Share',
                    subtitle: 'Search and share to your connections',
                    onTap: () {
                      Navigator.pop(ctx);
                      _openShareToConnectionsSheet(post);
                    },
                  ),
                  _buildFeedOptionTile(
                    icon: LucideIcons.messageCircle,
                    iconColor: const Color(0xFF69F0AE),
                    title: 'Comments',
                    subtitle:
                        'View and reply to ${post.commentsCount} comments',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCommentsCover(post);
                    },
                  ),
                  _buildFeedOptionTile(
                    icon: isSaved
                        ? LucideIcons.bookmarkCheck
                        : LucideIcons.bookmark,
                    iconColor: const Color(0xFFFFD700),
                    title: isSaved ? 'Remove from Saved' : 'Save to Saved List',
                    subtitle: isSaved
                        ? 'Remove from your saved list'
                        : 'Keep in Settings -> Saved List',
                    onTap: () {
                      Navigator.pop(ctx);
                      final nowSaved = SavedPostsManager.toggleSave(post);
                      setState(() {
                        if (nowSaved) {
                          _savedPosts.add(post.id);
                        } else {
                          _savedPosts.remove(post.id);
                        }
                      });
                      MorphingCapsule.show(
                        context,
                        icon: nowSaved
                            ? LucideIcons.bookmarkCheck
                            : LucideIcons.bookmarkMinus,
                        label: nowSaved
                            ? 'Saved to Saved List!'
                            : 'Removed from Saved',
                        color: const Color(0xFFFFD700),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openShareToConnectionsSheet(FeedPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allConnections = ChatStateStore.instance.conversations;
            final filtered = allConnections.where((c) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return c.name.toLowerCase().contains(q) ||
                  c.role.toLowerCase().contains(q);
            }).toList();

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E17).withOpacity(0.96),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(LucideIcons.share2,
                              color: Color(0xFF54C5F8), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Share to Connections',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          SpringButton(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                              child: const Icon(LucideIcons.x,
                                  size: 16, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.14)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.search,
                                size: 16, color: Colors.white54),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (val) {
                                  setSheetState(() => searchQuery = val);
                                },
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                cursorColor: const Color(0xFF54C5F8),
                                decoration: InputDecoration(
                                  hintText: 'Search connections or friends...',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching connections found',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final conn = filtered[i];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color:
                                              Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage:
                                              NetworkImage(conn.avatarUrl),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                conn.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                conn.role,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SpringButton(
                                          onTap: () {
                                            conn.messages.add(
                                              ChatMessage(
                                                id: 'share_${DateTime.now().millisecondsSinceEpoch}',
                                                text:
                                                    'Shared a post from @${post.username}: "${post.captionTitle}"',
                                                isMe: true,
                                                time: 'Just now',
                                                sentAt: DateTime.now(),
                                                mediaUrl: post.imageUrl,
                                                mediaType: 'image',
                                                mediaCaption:
                                                    '${post.captionTitle}\nby @${post.username}',
                                              ),
                                            );
                                            conn.lastMessage =
                                                'Shared a post from @${post.username}';
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Post shared with ${conn.name}!')),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF54C5F8)
                                                  .withOpacity(0.20),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: const Color(0xFF54C5F8)
                                                      .withOpacity(0.6)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(LucideIcons.send,
                                                    color: Color(0xFF54C5F8),
                                                    size: 13),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Send',
                                                  style: TextStyle(
                                                    color: Color(0xFF54C5F8),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeedOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.16),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withOpacity(0.35)),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: Colors.white.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }

  final Map<String, List<CommentItem>> _feedPostComments = {};

  List<CommentItem> _getCommentsForPost(FeedPost post) {
    return _feedPostComments.putIfAbsent(
        post.id,
        () => [
              CommentItem(
                id: 'c1_${post.id}',
                username: 'elena.codes',
                avatarUrl:
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop',
                text: 'The composition and lighting here is unreal! 😍',
                timestamp: '2h',
                likesCount: 24,
              ),
              CommentItem(
                id: 'c2_${post.id}',
                username: 'marcus_dev',
                avatarUrl:
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop',
                text: 'Clean aesthetic, looks super crisp.',
                timestamp: '1h',
                likesCount: 9,
              ),
              CommentItem(
                id: 'c3_${post.id}',
                username: 'sophia_ai',
                avatarUrl:
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop',
                text: 'Amazing shot! Love the colors. 💛',
                timestamp: '35m',
                likesCount: 14,
              ),
            ]);
  }

  void _showCommentsCover(FeedPost post) {
    setState(() {
      _coveredPostId = post.id;
      _coveredPostShowsComments = true;
      _activeActionPostId = null;
    });
  }

  void _openCommentsModal(FeedPost post) {
    final comments = _getCommentsForPost(post);
    final textCtrl = TextEditingController();
    String? replyingTo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E17).withOpacity(0.96),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.messageCircle,
                                    color: Color(0xFFFFD700), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Comments (${comments.length})',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x,
                                  color: Colors.white70, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: Colors.white.withOpacity(0.1), height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundImage:
                                        NetworkImage(comment.avatarUrl),
                                    backgroundColor: Colors.white12,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              comment.username,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              comment.timestamp,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.45),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () {
                                            setSheetState(() {
                                              replyingTo = comment.username;
                                            });
                                          },
                                          child: Text(
                                            'Reply',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setSheetState(() {
                                        comment.isLiked = !comment.isLiked;
                                        comment.likesCount +=
                                            comment.isLiked ? 1 : -1;
                                      });
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.heart,
                                          size: 15,
                                          color: comment.isLiked
                                              ? const Color(0xFFFF5252)
                                              : Colors.white38,
                                        ),
                                        if (comment.likesCount > 0) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${comment.likesCount}',
                                            style: TextStyle(
                                              color: comment.isLiked
                                                  ? const Color(0xFFFF5252)
                                                  : Colors.white38,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (replyingTo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          color: Colors.white.withOpacity(0.06),
                          child: Row(
                            children: [
                              Text(
                                'Replying to @$replyingTo',
                                style: const TextStyle(
                                    color: Color(0xFF54C5F8), fontSize: 12),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    setSheetState(() => replyingTo = null),
                                child: const Icon(LucideIcons.x,
                                    size: 14, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          border: Border(
                              top: BorderSide(
                                  color: Colors.white.withOpacity(0.1))),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundImage: NetworkImage(
                                context
                                            .watch<AuthProvider>()
                                            .currentUser
                                            ?.avatarUrl
                                            .isNotEmpty ==
                                        true
                                    ? context
                                        .watch<AuthProvider>()
                                        .currentUser!
                                        .avatarUrl
                                    : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.18)),
                                ),
                                child: TextField(
                                  controller: textCtrl,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: replyingTo != null
                                        ? 'Reply to @$replyingTo...'
                                        : 'Add a comment...',
                                    hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.45),
                                        fontSize: 13),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SpringButton(
                              onTap: () {
                                final text = textCtrl.text.trim();
                                if (text.isEmpty) return;
                                final auth = Provider.of<AuthProvider>(context,
                                    listen: false);
                                final user = auth.currentUser;
                                final String myUname =
                                    (user?.section?.isNotEmpty == true)
                                        ? user!.section!
                                        : (user?.name ?? 'You');
                                final myAvatar = (user?.avatarUrl?.isNotEmpty ==
                                        true)
                                    ? user!.avatarUrl
                                    : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
                                SupabaseDataService.addComment(
                                    postId: post.id,
                                    content: text,
                                    userId: user?.id);
                                setSheetState(() {
                                  comments.insert(
                                    0,
                                    CommentItem(
                                      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                                      username: myUname,
                                      avatarUrl: myAvatar,
                                      text: text,
                                      timestamp: 'Just now',
                                      replyTo: replyingTo,
                                      likesCount: 0,
                                    ),
                                  );
                                  textCtrl.clear();
                                  replyingTo = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD700),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.send,
                                    size: 14, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDescriptionCover(FeedPost post) {
    setState(() {
      _coveredPostId = post.id;
      _coveredPostShowsComments = false;
      _activeActionPostId = null;
    });
  }

  void _openDescriptionModal(FeedPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E17).withOpacity(0.96),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post.avatarUrl.isNotEmpty
                            ? NetworkImage(post.avatarUrl)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              post.location,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x,
                            color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                  const SizedBox(height: 14),
                  Text(
                    post.captionTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.captionBody,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.music,
                            size: 14, color: Color(0xFFFFD700)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${post.musicTitle} • ${post.musicArtist}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _oldShowDescriptionCover(FeedPost post) {
    setState(() {
      _coveredPostId = post.id;
      _coveredPostShowsComments = false;
    });
  }

  void _oldShowCommentsCover(FeedPost post) {
    setState(() {
      _coveredPostId = post.id;
      _coveredPostShowsComments = true;
      _activeActionPostId = null;
    });
  }

  void _closePostCover() {
    setState(() {
      _coveredPostId = null;
      _coveredPostShowsComments = false;
    });
  }

  void _openReelsScreen(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenReelsScreen(
          posts: _posts,
          initialIndex: initialIndex,
          initialLikedPostIds: _likedPosts,
          onLikeToggled: (post) => _triggerLike(post),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ThemeProvider.backgroundWarmWhite,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: _buildStoriesSection(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterTabsDelegate(child: _buildFilterTabs()),
          ),
          if (_isLoadingFeed)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF54C5F8),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            )
          else if (_posts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(LucideIcons.code2,
                            color: Color(0xFF54C5F8), size: 36),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'No Posts in Live Feed',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to share code snippets, projects, or moments to Supabase!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF54C5F8),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _openPostMomentSheet,
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Create First Post',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPostCard(_posts[index], index),
                childCount: _posts.length,
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  void _openPostMomentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16171E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share a Moment',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildMomentOption(
                      icon: LucideIcons.image,
                      label: 'Photo',
                      gradient: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      onTap: () async {
                        Navigator.pop(ctx);
                        final result = await getStoragePicker().pickImage();
                        if (result != null) {
                          _promptDestinationAndOpenStudio(result.pathOrDataUrl,
                              isVideo: false);
                        } else {
                          _promptDestinationAndOpenStudio(
                              'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=800',
                              isVideo: false);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMomentOption(
                      icon: LucideIcons.video,
                      label: 'Video',
                      gradient: const [Color(0xFFA855F7), Color(0xFF7E22CE)],
                      onTap: () async {
                        Navigator.pop(ctx);
                        final result = await getStoragePicker().pickVideo();
                        if (result != null) {
                          _promptDestinationAndOpenStudio(result.pathOrDataUrl,
                              isVideo: true);
                        } else {
                          _promptDestinationAndOpenStudio(
                              'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800',
                              isVideo: true);
                        }
                        // Video moment handled above
                        // dead
                        // dead
                        // dead
                        // dead
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMomentOption(
                      icon: LucideIcons.type,
                      label: 'Status',
                      gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                      onTap: () {
                        Navigator.pop(ctx);
                        _showTextStatusDialog();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMomentOption({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return SpringButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradient),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextStatusDialog() {
    final statusCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF16171E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        title: Text(
          'Post Status Update',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: statusCtrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "What's on your mind?",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeProvider.primaryGold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final text = statusCtrl.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogCtx);
                _addMomentStory(
                  'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500',
                  caption: text,
                );
              }
            },
            child: const Text('Post',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _promptDestinationAndOpenStudio(String mediaUrl,
      {required bool isVideo}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: const Color(0xFF0F111A).withOpacity(0.96),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Post For What?',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose where you want to share this media',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
                const SizedBox(height: 20),
                SpringButton(
                  onTap: () {
                    Navigator.pop(ctx);
                    _openPostStudio(
                      mediaUrl: mediaUrl,
                      isVideo: isVideo,
                      destination: PostDestination.story,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFD700).withOpacity(0.18),
                            border: Border.all(
                                color:
                                    const Color(0xFFFFD700).withOpacity(0.4)),
                          ),
                          child: const Icon(LucideIcons.circleDot,
                              color: Color(0xFFFFD700), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Story',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Crop, sketch, stickers & story caption · Disappears in 24h',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight,
                            color: Colors.white38, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SpringButton(
                  onTap: () {
                    Navigator.pop(ctx);
                    _openPostStudio(
                      mediaUrl: mediaUrl,
                      isVideo: isVideo,
                      destination: PostDestination.feed,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF54C5F8).withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF54C5F8).withOpacity(0.18),
                            border: Border.all(
                                color:
                                    const Color(0xFF54C5F8).withOpacity(0.4)),
                          ),
                          child: const Icon(LucideIcons.layoutGrid,
                              color: Color(0xFF54C5F8), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Main Feed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Crop, video trimmer, filters, rich descriptions & location',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight,
                            color: Colors.white38, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPostStudio({
    required String mediaUrl,
    required bool isVideo,
    required PostDestination destination,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostStudioScreen(
          mediaUrl: mediaUrl,
          isVideo: isVideo,
          initialDestination: destination,
          onPublish: ({
            required PostDestination destination,
            required String mediaUrl,
            required String? caption,
            required String? title,
            required String? description,
            required String? location,
            required String? musicTitle,
          }) async {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final user = auth.currentUser;
            final String myUname = (user?.section?.isNotEmpty == true)
                ? user!.section!
                : (user?.name ?? 'You');
            final myAvatar = (user?.avatarUrl?.isNotEmpty == true)
                ? user!.avatarUrl
                : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';

            if (destination == PostDestination.story) {
              final newItem = FeedStoryItem(
                id: 'my_item_${DateTime.now().millisecondsSinceEpoch}',
                imageUrl: mediaUrl,
                caption: caption ?? 'Story moment',
                time: 'Just now',
              );
              setState(() {
                _myStoryItems.add(newItem);
                if (_stories.isNotEmpty && _stories.first.isAddStory) {
                  _stories.first.items.clear();
                  _stories.first.items.addAll(_myStoryItems);
                }
              });
              final storySaved = await SupabaseDataService.createStory(
                title: caption ?? 'Story moment',
                mediaUrl: mediaUrl,
                userId: user?.id,
                authorUsername: myUname,
                authorFullName: user?.name ?? myUname,
                authorAvatar: myAvatar,
              );
              MorphingCapsule.show(
                context,
                icon: storySaved ? LucideIcons.sparkles : LucideIcons.cloudOff,
                label: storySaved
                    ? 'Story published to Supabase!'
                    : 'Story is local only. Check your connection and retry.',
                color: storySaved ? ThemeProvider.primaryGold : Colors.orange,
              );
            } else {
              final newPost = FeedPost(
                id: 'post_${DateTime.now().millisecondsSinceEpoch}',
                username: myUname,
                location: location ?? 'Tokyo Cloud',
                avatarUrl: myAvatar,
                imageUrl: mediaUrl,
                commentsCount: 0,
                sharesCount: 0,
                likesCount: 0,
                captionTitle: title ?? 'Fresh Upload',
                captionBody: description ?? 'Check out this new feed post!',
                musicTitle: musicTitle ?? 'Original Audio',
                musicArtist: myUname,
                musicCoverUrl:
                    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150',
                likedByAvatars: [],
                likedByText: 'Be the first to like this',
              );

              await LocalPostsCache.savePost(newPost);
              setState(() {
                _posts.insert(0, newPost);
                _reinitPostControllers();
              });
              final remoteId = SupabaseDataService.toValidUuid(newPost.id);
              final result = await SupabaseDataService.createPost(
                postId: remoteId,
                title: title,
                description: description ?? '',
                codeSnippet: mediaUrl,
                userId: user?.id,
                authorUsername: myUname,
                authorFullName: user?.name ?? myUname,
                authorAvatar: myAvatar,
              );

              if (result != null && result['id'] != null && mounted) {
                final confirmedId = result['id'].toString();
                await LocalPostsCache.updatePostId(newPost.id, confirmedId);
                if (!mounted) return;
                setState(() {
                  final index = _posts.indexWhere(
                    (item) => item.id == newPost.id,
                  );
                  if (index != -1) {
                    _posts[index] = _copyPostWithRemoteIdentity(
                      newPost,
                      id: confirmedId,
                      imageUrl: result['code_snippet']?.toString(),
                    );
                  }
                });
              }

              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              }

              MorphingCapsule.show(
                context,
                icon: result != null
                    ? LucideIcons.checkCheck
                    : LucideIcons.cloudOff,
                label: result != null
                    ? 'Post published to Supabase!'
                    : 'Saved locally. Supabase sync will retry automatically.',
                color:
                    result != null ? ThemeProvider.primaryGold : Colors.orange,
              );
            }
          },
        ),
      ),
    );
  }

  void _addMomentStory(String imageUrl, {String? caption}) {
    final newStory = FeedStory(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      username: 'You',
      imageUrl: imageUrl,
      timeAgo: 'Just now',
      items: [
        FeedStoryItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          imageUrl: imageUrl,
          caption: caption ?? 'My moment',
          time: 'Just now',
        ),
      ],
    );
    setState(() {
      _stories.insert(1, newStory);
    });
    MorphingCapsule.show(
      context,
      icon: LucideIcons.check,
      label: 'Moment shared!',
      color: ThemeProvider.primaryGold,
    );
  }

  // ─── STORIES ─────────────────────────────────────────────────────────────────

  final ScrollController _storyScrollController = ScrollController();

  Widget _buildStoriesSection() {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    final storiesHeight = isDesktop ? 168.0 : 220.0;
    final storyCardWidth = isDesktop ? 90.0 : 110.0;

    return Container(
      color: ThemeProvider.backgroundWarmWhite,
      padding:
          EdgeInsets.only(top: isDesktop ? 14 : 20, bottom: isDesktop ? 8 : 12),
      clipBehavior: Clip.none,
      child: SizedBox(
        height: storiesHeight,
        child: AnimatedBuilder(
          animation: _storyScrollController,
          builder: (context, child) {
            return ListView.builder(
              clipBehavior: Clip.none,
              controller: _storyScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                  left: 12, right: 12, top: 12, bottom: 8),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                // Liquid wave math: calculate distance from center of screen
                double itemPosition = (index * (storyCardWidth + 10.0)) -
                    (_storyScrollController.hasClients
                        ? _storyScrollController.offset
                        : 0.0);
                double distanceFromCenter = (itemPosition - 200).abs();

                double waveOffset = 0;
                if (distanceFromCenter < 300) {
                  waveOffset = (10.0 * (1 - (distanceFromCenter / 300)));
                }

                return Transform.translate(
                  offset: Offset(0, -waveOffset),
                  child:
                      _buildStoryCard(_stories[index], index, storyCardWidth),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoryCard(FeedStory story, int index, [double width = 110]) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppAnimations.expressive,
      curve: AppAnimations.overshoot,
      builder: (context, val, child) => Opacity(
        opacity: val.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.85 + 0.15 * val, child: child),
      ),
      child: SpringButton(
        onTap: () {
          if (!story.isAddStory) {
            final userStories = _stories.where((s) => !s.isAddStory).toList();
            final initialIdx =
                userStories.indexOf(story).clamp(0, userStories.length - 1);
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    StoryViewerScreen(
                  allStories: userStories,
                  initialStoryIndex: initialIdx,
                  onCompleted: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          story.isViewed = true;
                          _stories.remove(story);
                          _stories.add(story);
                        });
                      }
                    });
                  },
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: AppAnimations.expressiveEntrance,
                    )),
                    child: child,
                  );
                },
              ),
            ).then((_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && story.isViewed && _stories.last.id != story.id) {
                  setState(() {
                    _stories.remove(story);
                    _stories.add(story);
                  });
                }
              });
            });
          } else {
            if (_myStoryItems.isNotEmpty) {
              final myStory = FeedStory(
                id: 'my_story',
                username: 'Your Story',
                imageUrl: _myStoryItems.last.imageUrl,
                timeAgo: 'Just now',
              );
              myStory.items.clear();
              myStory.items.addAll(_myStoryItems);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, anim, secAnim) =>
                      StoryViewerScreen(story: myStory),
                  transitionsBuilder: (context, anim, secAnim, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
              );
            } else {
              _openPostMomentSheet();
            }
          }
        },
        scale: story.isAddStory ? 1.0 : 0.92,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: story.isAddStory
                ? (_myStoryItems.isNotEmpty
                    ? Border.all(color: const Color(0xFFFFD700), width: 1.8)
                    : Border.all(
                        color: Colors.white.withOpacity(0.12), width: 1.2))
                : story.isViewed
                    ? Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.2,
                      )
                    : Border.all(
                        color: Colors.white.withOpacity(0.92),
                        width: 1.8,
                      ),
            boxShadow: [
              if (!story.isAddStory && !story.isViewed)
                BoxShadow(
                  color: Colors.white.withOpacity(0.38),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              BoxShadow(
                color: story.isAddStory
                    ? ThemeProvider.primaryGold.withOpacity(0.25)
                    : Colors.black.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: story.isAddStory
                ? _buildAddStoryCard(story)
                : _buildUserStoryCard(story),
          ),
        ),
      ),
    );
  }

  Widget _buildAddStoryCard(FeedStory story) {
    final bool hasMyStory = _myStoryItems.isNotEmpty;
    final String displayUrl =
        hasMyStory ? _myStoryItems.last.imageUrl : story.imageUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          displayUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF1B1D26),
            child:
                const Icon(LucideIcons.user, color: Colors.white38, size: 36),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.35),
                Colors.black.withOpacity(0.85),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: SpringButton(
            onTap: _openPostMomentSheet,
            scale: 0.85,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:
                  const Icon(LucideIcons.plus, color: Colors.black, size: 18),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Story',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                hasMyStory ? 'Tap to view' : 'Tap + to add',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _oldBuildAddStoryCard() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD878), Color(0xFFF4B223), Color(0xFFE09800)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpringButton(
              onTap: _openPostMomentSheet,
              scale: 0.85,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.35),
                ),
                child:
                    const Icon(LucideIcons.plus, color: Colors.white, size: 20),
              ),
            ),
            const Spacer(),
            Text(
              'Share\na moment',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStoryCard(FeedStory story) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          story.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF2A2A2A),
            child: const Icon(Icons.person, color: Colors.white54, size: 40),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.05),
                Colors.black.withOpacity(0.72),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Grey dimmed layer overlay if watched
        if (story.isViewed)
          Container(
            color: Colors.black.withOpacity(0.42),
          ),
        if (story.isLive)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ThemeProvider.primaryGold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIVE',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 14,
          left: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.username,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: story.isLive
                          ? ThemeProvider.primaryGold
                          : Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    story.timeAgo,
                    style: GoogleFonts.inter(
                      color: story.isLive
                          ? ThemeProvider.primaryGold
                          : Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── FILTER TABS ─────────────────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    return Container(
      color: ThemeProvider.backgroundWarmWhite,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.asMap().entries.map((entry) {
            final idx = entry.key;
            final label = entry.value;
            final isActive = idx == _activeFilterIndex;
            return _buildFilterChip(label, idx, isActive);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, bool isActive) {
    final bool hasCircle = index == 2;

    return SpringButton(
      onTap: () {
        setState(() => _activeFilterIndex = index);
        // Spring bounce feedback
        _filterControllers[index]
          ..reset()
          ..animateWith(SpringSimulation(AppAnimations.bouncySpring, 0, 1, 12));
      },
      scale: 0.90,
      child: AnimatedBuilder(
        animation: _filterControllers[index],
        builder: (context, child) {
          final bounce = _filterControllers[index].value;
          return Transform.scale(
            scale: 1.0 + bounce * 0.04,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: AppAnimations.quick,
          curve: AppAnimations.snappy,
          margin: const EdgeInsets.only(right: 10),
          padding: EdgeInsets.symmetric(
            horizontal: hasCircle ? 12 : 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: isActive
                ? Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index == 0) ...[
                AnimatedContainer(
                  duration: AppAnimations.quick,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.plus,
                      color: isActive ? Colors.black : Colors.white, size: 12),
                ),
                const SizedBox(width: 6),
              ],
              if (hasCircle) ...[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              AnimatedDefaultTextStyle(
                duration: AppAnimations.quick,
                style: GoogleFonts.inter(
                  color: isActive ? Colors.white : ThemeProvider.textMutedGray,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
                child: Text(label),
              ),
              if (index == _filters.length - 1) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronDown,
                    color: ThemeProvider.textMutedGray, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── POST CARD ───────────────────────────────────────────────────────────────

  Widget _buildPostCard(FeedPost post, int index) {
    final bool isLiked = _likedPosts.contains(post.id);
    final bool isSaved = _savedPosts.contains(post.id);
    final int visibleLikes = post.likesCount;

    return AnimatedBuilder(
      animation: index < _postControllers.length
          ? _postControllers[index]
          : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) => FadeTransition(
        opacity: index < _postFades.length
            ? _postFades[index]
            : const AlwaysStoppedAnimation(1.0),
        child: SlideTransition(
          position: index < _postSlides.length
              ? _postSlides[index]
              : const AlwaysStoppedAnimation(Offset.zero),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 580;
            // On desktop/wide screens, constrain width to 500-520 and use a balanced aspect ratio
            // so at least one full post card is 100% visible on screen without excessive scrolling!
            final cardWidth = isWide ? 510.0 : constraints.maxWidth;
            final cardAspectRatio = isWide ? (4.0 / 3.6) : (3.0 / 4.2);
            final cardHeight = cardWidth / cardAspectRatio;
            final cardSize = Size(cardWidth, cardHeight);

            return Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isWide ? 22 : 0),
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D10),
                    borderRadius: BorderRadius.circular(isWide ? 22 : 0),
                    border: isWide
                        ? Border.all(color: const Color(0x26FFFFFF), width: 1)
                        : null,
                    boxShadow: isWide
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (post.isVideo) {
                        setState(() {
                          if (_pausedVideoPostIds.contains(post.id)) {
                            _pausedVideoPostIds.remove(post.id);
                          } else {
                            _pausedVideoPostIds.add(post.id);
                          }
                        });
                      } else {
                        _openReelsScreen(index);
                      }
                    },
                    onDoubleTap: () => _likePost(post),
                    onLongPressStart: (details) =>
                        _startQuickActions(post, details, cardSize),
                    onLongPressMoveUpdate: _updateQuickActions,
                    onLongPressEnd: (_) => _finishQuickActions(post),
                    onLongPressCancel: () =>
                        setState(() => _activeActionPostId = null),
                    child: Stack(
                      children: [
                        // Full-width image cover
                        Positioned.fill(
                          child: Image.network(
                            post.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1A1A1A),
                              child: const Icon(Icons.image,
                                  color: Colors.white38, size: 60),
                            ),
                          ),
                        ),

                        // Top gradient
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: const Alignment(0, -0.2),
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom gradient
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.35),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Video Central Pause Indicator
                        if (post.isVideo &&
                            _pausedVideoPostIds.contains(post.id))
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white30, width: 2),
                                ),
                                child: const Icon(
                                  LucideIcons.pause,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),

                        // ── TOP BAR (User Info) ──
                        Positioned(
                          top: 18,
                          left: 14,
                          right: 80, // Leave space on the right
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SpringButton(
                                onTap: () => _openUserProfile(post),
                                scale: 0.90,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5),
                                  ),
                                  child: CircleAvatar(
                                    radius: 17,
                                    backgroundImage: post.avatarUrl.isNotEmpty
                                        ? NetworkImage(post.avatarUrl)
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _openUserProfile(post),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(post.username,
                                              style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified,
                                              color: Colors.white, size: 13),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.mapPin,
                                              color: Colors.white70, size: 11),
                                          const SizedBox(width: 4),
                                          Text(post.location,
                                              style: GoogleFonts.inter(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── SWIPE ACTION BAR ──
                        Positioned(
                          top: 18,
                          right: 14,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (post.isVideo)
                                SpringButton(
                                  onTap: () {
                                    final isMuted =
                                        _mutedVideoPostIds.contains(post.id);
                                    setState(() {
                                      if (isMuted) {
                                        _mutedVideoPostIds.remove(post.id);
                                      } else {
                                        _mutedVideoPostIds.add(post.id);
                                      }
                                    });
                                    MorphingCapsule.show(
                                      context,
                                      icon: isMuted
                                          ? LucideIcons.volume2
                                          : LucideIcons.volumeX,
                                      label: isMuted
                                          ? 'Sound unmuted'
                                          : 'Sound muted',
                                      color: isMuted
                                          ? const Color(0xFF54C5F8)
                                          : Colors.white70,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Icon(
                                      _mutedVideoPostIds.contains(post.id)
                                          ? LucideIcons.volumeX
                                          : LucideIcons.volume2,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              SwipeActionBar(
                                isLiked: isLiked,
                                likesCount: visibleLikes,
                                onLikeToggled: () => _triggerLike(post),
                              ),
                            ],
                          ),
                        ),

                        if (false)
                          quick_actions.FloatingActionBar(
                            position: _actionBarPosition,
                            touchPosition: _actionTouchPosition,
                            onActionSelected: (_) {},
                            onCancel: () =>
                                setState(() => _activeActionPostId = null),
                            commentsCount: post.commentsCount,
                            sharesCount: post.sharesCount,
                            width: _activeActionBarWidth,
                          ),

                        // ─── FULL-SCREEN INTERACTIVE OVERLAY ───
                        Positioned.fill(
                          child: InteractiveBottomCards(
                            post: post,
                            isSaved: isSaved,
                            onSaveToggled: () => _triggerSave(post.id),
                            onShowDescription: () =>
                                _showDescriptionCover(post),
                            initialMode: (_coveredPostId == post.id)
                                ? UIMode.fullScreen
                                : UIMode.snippet,
                            initialPageIndex: (_coveredPostId == post.id &&
                                    _coveredPostShowsComments)
                                ? 1
                                : 0,
                            onModeChanged: (mode) {
                              if (mode != UIMode.fullScreen &&
                                  _coveredPostId == post.id) {
                                setState(() {
                                  _coveredPostId = null;
                                  _coveredPostShowsComments = false;
                                });
                              }
                            },
                          ),
                        ),
                        if (_activeActionPostId == post.id)
                          quick_actions.FloatingActionBar(
                            position: _actionBarPosition,
                            touchPosition: _actionTouchPosition,
                            onActionSelected: (idx) =>
                                _executeQuickAction(post, idx),
                            onCancel: () =>
                                setState(() => _activeActionPostId = null),
                            commentsCount: post.commentsCount,
                            sharesCount: post.sharesCount,
                            width: _activeActionBarWidth,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrostedCard({required Widget child, double borderRadius = 20}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ─── PICKED FOR YOU ──────────────────────────────────────────────────────────

  Widget _buildPickedForYouSection() {
    if (_pickedPosts.isEmpty) return const SizedBox.shrink();
    return Container(
      color: ThemeProvider.backgroundWarmWhite,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sparkles,
                      color: ThemeProvider.primaryGold, size: 18),
                  const SizedBox(width: 7),
                  Text(
                    'Picked for you',
                    style: GoogleFonts.inter(
                      color: ThemeProvider.textCharcoal,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              SpringButton(
                onTap: () {},
                child: Text(
                  'See all',
                  style: GoogleFonts.inter(
                    color: ThemeProvider.primaryGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _pickedPosts.length,
              itemBuilder: (context, index) => SpringButton(
                onTap: () {
                  if (_posts.isNotEmpty)
                    _openReelsScreen(index % _posts.length);
                },
                scale: 0.94,
                borderRadius: BorderRadius.circular(18),
                child: _buildPickedPostCard(_pickedPosts[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickedPostCard(PickedPost post) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF2A2A2A)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundImage: NetworkImage(post.avatarUrl),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.tag,
                          style: GoogleFonts.inter(
                            color: ThemeProvider.primaryGold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    post.postsCount,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter tab persistent header ────────────────────────────────────────────

class _FilterTabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _FilterTabsDelegate({required this.child});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_FilterTabsDelegate oldDelegate) => true;
}
