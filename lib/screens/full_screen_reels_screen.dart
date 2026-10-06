import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/app_animations.dart';
import '../utils/feed_mock_data.dart';
import '../widgets/spring_button.dart';
import '../widgets/swipe_action_bar.dart';
import '../widgets/interactive_bottom_cards.dart';
import '../widgets/floating_action_bar.dart' as quick_actions;
import '../screens/user_profile_detail_screen.dart';
import '../utils/mock_data.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// ── Multi-device drag behavior (Touch, Mouse, Trackpad, Stylus) ──────────────
class _ReelsScrollBehavior extends MaterialScrollBehavior {
  const _ReelsScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class FullScreenReelsScreen extends StatefulWidget {
  final List<FeedPost> posts;
  final int initialIndex;

  const FullScreenReelsScreen({
    super.key,
    required this.posts,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenReelsScreen> createState() => _FullScreenReelsScreenState();
}

class _FullScreenReelsScreenState extends State<FullScreenReelsScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  // Hold to hide UI / Hold to show clean media feature
  bool _isHoldingToHideUI = false;

  // Like & saved states per post id
  final Set<String> _likedPostIds = {};
  final Set<String> _savedPostIds = {};

  // Animated heart pop on double tap
  bool _showHeartAnim = false;
  Offset _heartAnimPosition = Offset.zero;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  // Track if full-screen Story/Comments modal sheet is expanded
  bool _isFullScreenModalOpen = false;
  String? _reelsCoveredPostId;
  bool _reelsCoveredShowsComments = false;


  // Floating Action Bar (hold & drag quick actions over media)
  String? _activeActionPostId;
  Offset _actionBarPosition = Offset.zero;
  Offset _actionTouchPosition = Offset.zero;
  int _activeActionIndex = 2;
  double _activeActionBarWidth = 0;

  // Desktop Split Panel States (persisted across post scrolling)
  bool _desktopDescriptionOpen = false;
  bool _desktopCommentsOpen = false;

  final Map<String, List<CommentItem>> _desktopPostComments = {};
  final Set<String> _desktopExpandedCommentIds = {};
  final TextEditingController _desktopCommentController = TextEditingController();
  final FocusNode _desktopCommentFocusNode = FocusNode();
  String? _desktopReplyingTo;
  CommentItem? _desktopReplyingToComment;

  List<CommentItem> _getCommentsForPost(FeedPost post) {
    return _desktopPostComments.putIfAbsent(post.id, () => [
      CommentItem(
        id: 'dc-1',
        username: 'elena.codes',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop',
        text: 'This looks absolutely amazing! The liquid glass blur feels so futuristic. 🔥',
        timestamp: '2h',
        likesCount: 24,
        isLiked: false,
        isSelf: false,
        replies: [
          CommentItem(
            id: 'dc-1-r1',
            username: 'alexj',
            avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
            text: 'Thank you! The custom GLSL shader cache makes a huge difference.',
            timestamp: '1h',
            likesCount: 4,
            isLiked: true,
            isSelf: true,
            replyTo: 'elena.codes',
          ),
          CommentItem(
            id: 'dc-1-r2',
            username: 'dev.shots',
            avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop',
            text: 'Agreed, the specular highlight along the edges is super crisp.',
            timestamp: '45m',
            likesCount: 2,
            isLiked: false,
            isSelf: false,
            replyTo: 'elena.codes',
          ),
        ],
      ),
      CommentItem(
        id: 'dc-2',
        username: 'marcus_dev',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop',
        text: 'Where was this shot taken? The lighting in the evening is perfection.',
        timestamp: '1h',
        likesCount: 12,
        isLiked: true,
        isSelf: false,
        replies: [
          CommentItem(
            id: 'dc-2-r1',
            username: 'dev.shots',
            avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop',
            text: 'Higashiyama district in Kyoto near the Yasaka Pagoda right at dusk! ⛩️',
            timestamp: '50m',
            likesCount: 6,
            isLiked: false,
            isSelf: false,
            replyTo: 'marcus_dev',
          ),
        ],
      ),
      CommentItem(
        id: 'dc-3',
        username: 'alexj',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
        text: 'Testing out the new 120fps hardware acceleration on this render! ✨',
        timestamp: '35m',
        likesCount: 9,
        isLiked: false,
        isSelf: true,
      ),
    ]);
  }

  void _submitDesktopComment(FeedPost post) {
    final text = _desktopCommentController.text.trim();
    if (text.isEmpty) return;

    final comments = _getCommentsForPost(post);
    final newComment = CommentItem(
      id: 'dc-${DateTime.now().millisecondsSinceEpoch}',
      username: 'alexj',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
      text: text,
      timestamp: 'Just now',
      likesCount: 0,
      isLiked: false,
      isSelf: true,
      replyTo: _desktopReplyingTo,
    );

    setState(() {
      if (_desktopReplyingToComment != null) {
        _desktopReplyingToComment!.replies.add(newComment);
        _desktopExpandedCommentIds.add(_desktopReplyingToComment!.id);
      } else {
        comments.insert(0, newComment);
      }
      _desktopCommentController.clear();
      _desktopReplyingTo = null;
      _desktopReplyingToComment = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.3)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
    ]).animate(_heartAnimController);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartAnimController);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimController.dispose();
    _desktopCommentController.dispose();
    _desktopCommentFocusNode.dispose();
    super.dispose();
  }

  void _openUserProfile(FeedPost post) {
    final user = MockData.getUserProfileForAuthor(
      username: post.username,
      avatarUrl: post.avatarUrl,
      location: post.location,
    );
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          return UserProfileDetailScreen(user: user);
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

  void _triggerDoubleTapLike(TapDownDetails details, FeedPost post) {
    setState(() {
      _likedPostIds.add(post.id);
      _heartAnimPosition = details.localPosition;
      _showHeartAnim = true;
    });

    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _showHeartAnim = false);
      }
    });
  }

  void _toggleLike(FeedPost post) {
    setState(() {
      if (_likedPostIds.contains(post.id)) {
        _likedPostIds.remove(post.id);
      } else {
        _likedPostIds.add(post.id);
      }
    });
  }

  void _toggleSave(FeedPost post) {
    setState(() {
      if (_savedPostIds.contains(post.id)) {
        _savedPostIds.remove(post.id);
      } else {
        _savedPostIds.add(post.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No posts available',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              SpringButton(
                onTap: () => Navigator.of(context).pop(),
                child: const Text('Back',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_isFullScreenModalOpen && !_desktopCommentsOpen && !_desktopDescriptionOpen && _reelsCoveredPostId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _isFullScreenModalOpen = false;
          _reelsCoveredPostId = null;
          _reelsCoveredShowsComments = false;
          _desktopCommentsOpen = false;
          _desktopDescriptionOpen = false;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(

        children: [
          // ── Vertical Reels Swiper PageView ─────────────────────────────────
          ScrollConfiguration(
            behavior: const _ReelsScrollBehavior(),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: _isFullScreenModalOpen
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemCount: widget.posts.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _isFullScreenModalOpen = false;
                });
              },
              itemBuilder: (context, index) {
                final post = widget.posts[index];
                return _buildReelPage(post);
              },
            ),
          ),

          // ── Double Tap Floating Animated Heart ─────────────────────────────
          if (_showHeartAnim)
            Positioned(
              left: _heartAnimPosition.dx - 45,
              top: _heartAnimPosition.dy - 45,
              child: AnimatedBuilder(
                animation: _heartAnimController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartScale.value,
                    child: Opacity(
                      opacity: _heartOpacity.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.6),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Color(0xFFFF2A55),
                          size: 90,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );


  }

  // ── Dispatcher between Desktop & Mobile ───────────────────────────────────
  Widget _buildReelPage(FeedPost post) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    if (isDesktop) {
      return _buildDesktopReelPage(post);
    }
    return _buildMobileReelPage(post);
  }

  // ── Single Reel Page (Mobile UI/UX preserved intact) ──────────────────────
  Widget _buildMobileReelPage(FeedPost post) {
    final isLiked = _likedPostIds.contains(post.id);
    final isSaved = _savedPostIds.contains(post.id);
    final visibleLikes = post.likesCount + (isLiked ? 1 : 0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background High-Res Image / Media ──────────────────────────────
        Positioned.fill(
          child: Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF141418),
              child: const Center(
                child:
                    Icon(LucideIcons.imageOff, color: Colors.white24, size: 48),
              ),
            ),
          ),
        ),

        // ── Top Gradient Vignette (For readable header) ────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 140,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.75),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Bottom Gradient Vignette ───────────────────────────────────────
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

        // ── Hold-to-Hide UI & Double-Tap Heart Touch Listener ──────────────
        Positioned.fill(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTapDown: (details) => _triggerDoubleTapLike(details, post),
                onDoubleTap: () {},
                onLongPressStart: (details) {
                  setState(() => _isHoldingToHideUI = true);
                  _startQuickActions(post, details, size);
                },
                onLongPressMoveUpdate: _updateQuickActions,
                onLongPressEnd: (_) {
                  setState(() => _isHoldingToHideUI = false);
                  _finishQuickActions(post);
                },
                onLongPressCancel: () {
                  setState(() {
                    _isHoldingToHideUI = false;
                    _activeActionPostId = null;
                  });
                },
              );
            },
          ),
        ),

        // ── Top User Header Bar & Swipe Action Bar ──────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 14,
          right: 14,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _isHoldingToHideUI ? 0.0 : 1.0,
            child: Row(
              children: [
                // Frosted Glass Back Button
                SpringButton(
                  onTap: () => Navigator.of(context).pop(),
                  scale: 0.90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: const Icon(LucideIcons.arrowLeft,
                            color: Colors.white, size: 19),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Author Avatar
                SpringButton(
                  onTap: () => _openUserProfile(post),
                  scale: 0.90,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundImage: NetworkImage(post.avatarUrl),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Author Name & Location
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openUserProfile(post),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.username,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                            Flexible(
                              child: Text(
                                post.location,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right Swipe Action Bar (Like count + Heart icon + actions)
                SwipeActionBar(
                  isLiked: isLiked,
                  likesCount: visibleLikes,
                  onLikeToggled: () => _toggleLike(post),
                ),
              ],
            ),
          ),
        ),

        // ── CodeSnap Custom Interactive Bottom Cards ────────────────────────
        Positioned.fill(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _isHoldingToHideUI ? 0.0 : 1.0,
            child: InteractiveBottomCards(
              post: post,
              isSaved: isSaved,
              onSaveToggled: () => _toggleSave(post),
              onShowDescription: () {},
              initialMode: (_reelsCoveredPostId == post.id)
                  ? UIMode.fullScreen
                  : UIMode.snippet,
              initialPageIndex:
                  (_reelsCoveredPostId == post.id && _reelsCoveredShowsComments)
                      ? 1
                      : 0,
              onModeChanged: (mode) {
                setState(() {
                  _isFullScreenModalOpen = (mode == UIMode.fullScreen);
                  if (mode != UIMode.fullScreen && _reelsCoveredPostId == post.id) {
                    _reelsCoveredPostId = null;
                    _reelsCoveredShowsComments = false;
                  }
                });
              },

            ),
          ),
        ),

        // ── Floating Action Bar (hold & drag quick actions overlay) ─────────
        if (_activeActionPostId == post.id)
          quick_actions.FloatingActionBar(
            position: _actionBarPosition,
            touchPosition: _actionTouchPosition,
            onActionSelected: (idx) {
              setState(() {
                _isHoldingToHideUI = false;
                _activeActionPostId = null;
              });
              _executeQuickAction(post, idx);
            },
            onCancel: () => setState(() {
              _isHoldingToHideUI = false;
              _activeActionPostId = null;
            }),
            commentsCount: post.commentsCount,
            sharesCount: post.sharesCount,
            width: _activeActionBarWidth,
          ),
      ],
    );
  }

  // ── Windows Desktop Reel Page (Liquid Glass Background + Split View) ───────
  Widget _buildDesktopReelPage(FeedPost post) {
    final isLiked = _likedPostIds.contains(post.id);
    final visibleLikes = post.likesCount + (isLiked ? 1 : 0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Liquid Glass Ambient Backdrop (Image with heavy blur) ────────
        Positioned.fill(
          child: Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF09090B)),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
            child: Container(
              color: const Color(0xFF09090B).withOpacity(0.75),
            ),
          ),
        ),
        // Ambient glass radial highlight circles
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF54C5F8).withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── 2. Top Header Bar ──────────────────────────────────────────────
        Positioned(
          top: 14,
          left: 24,
          right: 24,
          child: Row(
            children: [
              SpringButton(
                onTap: () => Navigator.of(context).pop(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 19),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Author Avatar
              SpringButton(
                onTap: () => _openUserProfile(post),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(post.avatarUrl),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Author Name & Location
              GestureDetector(
                onTap: () => _openUserProfile(post),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.username,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.verified, color: Colors.white, size: 13),
                      ],
                    ),
                    Text(
                      post.location,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Top Right Swipe Action Bar (Like count + Heart icon + actions)
              SwipeActionBar(
                isLiked: isLiked,
                likesCount: visibleLikes,
                onLikeToggled: () => _toggleLike(post),
              ),
            ],
          ),
        ),

        // ── 3. Desktop Body Layout (Split View / Contained Image) ──────────
        Positioned.fill(
          top: 76,
          bottom: 20,
          left: 24,
          right: 24,
          child: _buildDesktopBodyLayout(post),
        ),
      ],
    );
  }

  // ── Desktop Body Layout (Handles Dual Panel, Single Panel + Post, or Post Only) ──
  Widget _buildDesktopBodyLayout(FeedPost post) {
    // Case 1: Both open -> Split view: Left = Description, Right = Comments
    if (_desktopDescriptionOpen && _desktopCommentsOpen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildDesktopDescriptionPanel(
              post,
              onDismiss: () => setState(() => _desktopDescriptionOpen = false),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildDesktopCommentsPanel(
              post,
              onDismiss: () => setState(() => _desktopCommentsOpen = false),
            ),
          ),
        ],
      );
    }

    // Case 2: Description open, Comments closed -> Left = Description, Right = Contained Post
    if (_desktopDescriptionOpen && !_desktopCommentsOpen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _buildDesktopDescriptionPanel(
              post,
              onDismiss: () => setState(() => _desktopDescriptionOpen = false),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 6,
            child: _buildContainedPostImage(post),
          ),
        ],
      );
    }

    // Case 3: Comments open, Description closed -> Left = Contained Post with Compact Description, Right = Comments
    if (!_desktopDescriptionOpen && _desktopCommentsOpen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildContainedPostImage(post),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: _buildDesktopCompactDescription(post),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 5,
            child: _buildDesktopCommentsPanel(
              post,
              onDismiss: () => setState(() => _desktopCommentsOpen = false),
            ),
          ),
        ],
      );
    }

    // Case 4: Both closed -> Clean full view: Center = Contained Post Image in original size/ratio, Bottom Left = Compact Description
    // Floating action bar clutter removed as requested; long-press on post triggers quick action popup
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildContainedPostImage(post),
        Positioned(
          left: 0,
          bottom: 0,
          child: _buildDesktopCompactDescription(post),
        ),
      ],
    );
  }

  // ── Contained Post Image (Shows in original size / natural aspect ratio, not stretched) ──
  Widget _buildContainedPostImage(FeedPost post) {
    final cardMaxHeight = MediaQuery.of(context).size.height * 0.82;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: cardMaxHeight,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.20), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (ctx, innerConstraints) {
            final w = innerConstraints.maxWidth.isFinite ? innerConstraints.maxWidth : 680.0;
            final h = innerConstraints.maxHeight.isFinite ? innerConstraints.maxHeight : cardMaxHeight;
            final cardSize = Size(w, h);

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! < -150) {
                  // Swipe up opens both description left & comments right!
                  setState(() {
                    _desktopDescriptionOpen = true;
                    _desktopCommentsOpen = true;
                  });
                }
              },
              onLongPressStart: (details) =>
                  _startQuickActions(post, details, cardSize),
              onLongPressMoveUpdate: _updateQuickActions,
              onLongPressEnd: (_) => _finishQuickActions(post),
              onLongPressCancel: () =>
                  setState(() => _activeActionPostId = null),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Image.network(
                    post.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 380,
                      color: const Color(0xFF14151C),
                      child: const Center(
                        child: Icon(LucideIcons.imageOff, color: Colors.white24, size: 48),
                      ),
                    ),
                  ),
                  if (_activeActionPostId == post.id)
                    quick_actions.FloatingActionBar(
                      position: _actionBarPosition,
                      touchPosition: _actionTouchPosition,
                      onActionSelected: (idx) {
                        setState(() => _activeActionPostId = null);
                        _executeQuickAction(post, idx);
                      },
                      onCancel: () =>
                          setState(() => _activeActionPostId = null),
                      commentsCount: post.commentsCount,
                      sharesCount: post.sharesCount,
                      width: _activeActionBarWidth,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Desktop Description Panel (With 'X' Dismiss Button) ─────────────────────
  Widget _buildDesktopDescriptionPanel(FeedPost post, {required VoidCallback onDismiss}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: "Description" and 'X' close button
              Row(
                children: [
                  const Icon(LucideIcons.fileText, color: Color(0xFF54C5F8), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Description',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SpringButton(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                post.captionTitle,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 14),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.captionBody * 3,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14.5,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Music Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.music, color: Color(0xFF54C5F8), size: 14),
                            const SizedBox(width: 8),
                            Text(
                              '${post.musicTitle} • ${post.musicArtist}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Author info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(post.avatarUrl),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Shared by ${post.username}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Desktop Comments Panel (With Reply, Likes, Delete Self & 'X' Dismiss) ──
  Widget _buildDesktopCommentsPanel(FeedPost post, {required VoidCallback onDismiss}) {
    final comments = _getCommentsForPost(post);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Bar: "Comments (count)" and 'X' close button
              Row(
                children: [
                  const Icon(LucideIcons.messageSquare, color: Color(0xFF54C5F8), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Comments',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${comments.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  SpringButton(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Comments List with Nested Replies & Long-Press Option Sheet
              Expanded(
                child: comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final hasReplies = comment.replies.isNotEmpty;
                          final isExpanded = _desktopExpandedCommentIds.contains(comment.id);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDesktopSingleCommentRow(comment, post: post),
                              // Nested replies toggle and list
                              if (hasReplies) ...[
                                Padding(
                                  padding: const EdgeInsets.only(left: 42, bottom: 8),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        if (isExpanded) {
                                          _desktopExpandedCommentIds.remove(comment.id);
                                        } else {
                                          _desktopExpandedCommentIds.add(comment.id);
                                        }
                                      });
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 1,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isExpanded
                                              ? 'Hide replies'
                                              : 'View ${comment.replies.length} replies',
                                          style: const TextStyle(
                                            color: Color(0xFF54C5F8),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                          color: const Color(0xFF54C5F8),
                                          size: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 36, bottom: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Colors.white.withOpacity(0.15),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.only(left: 14),
                                      child: Column(
                                        children: comment.replies
                                            .map((r) => _buildDesktopSingleCommentRow(
                                                  r,
                                                  parentComment: comment,
                                                  post: post,
                                                  isReply: true,
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          );
                        },
                      ),
              ),
              // Replying banner
              if (_desktopReplyingTo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.reply, size: 11, color: Color(0xFF54C5F8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Replying to @$_desktopReplyingTo', style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11.5)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _desktopReplyingTo = null;
                          _desktopReplyingToComment = null;
                        }),
                        child: const Icon(LucideIcons.x, size: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              // Input bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: TextField(
                        controller: _desktopCommentController,
                        focusNode: _desktopCommentFocusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: _desktopReplyingTo != null ? 'Reply to @$_desktopReplyingTo...' : 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12.5),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (_) => _submitDesktopComment(post),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SpringButton(
                    onTap: () => _submitDesktopComment(post),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF54C5F8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.send, size: 14, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Desktop Single Comment Row (No Direct Delete Button - Long-press for Options) ──
  Widget _buildDesktopSingleCommentRow(
    CommentItem comment, {
    CommentItem? parentComment,
    required FeedPost post,
    bool isReply = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showDesktopCommentOptionsMenu(comment, parentComment: parentComment, post: post),
      child: Padding(
        padding: EdgeInsets.only(bottom: isReply ? 8 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: isReply ? 12 : 15,
              backgroundImage: NetworkImage(comment.avatarUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.username,
                        style: TextStyle(
                          color: comment.isSelf ? const Color(0xFF54C5F8) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isReply ? 11.5 : 12.5,
                        ),
                      ),
                      if (comment.isSelf) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF54C5F8).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('YOU', style: TextStyle(color: Color(0xFF54C5F8), fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        comment.timestamp,
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10.5),
                      ),
                    ],
                  ),
                  if (comment.replyTo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Replying to @${comment.replyTo}',
                      style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    comment.text,
                    style: TextStyle(color: Colors.white, fontSize: isReply ? 12.5 : 13, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Reply button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _desktopReplyingTo = comment.username;
                            _desktopReplyingToComment = parentComment ?? comment;
                          });
                          _desktopCommentFocusNode.requestFocus();
                        },
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Options hint
                      GestureDetector(
                        onTap: () => _showDesktopCommentOptionsMenu(comment, parentComment: parentComment, post: post),
                        child: Text(
                          'Options',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Like button with count
            SpringButton(
              onTap: () {
                setState(() {
                  comment.isLiked = !comment.isLiked;
                  comment.likesCount += comment.isLiked ? 1 : -1;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    comment.isLiked ? Icons.favorite : LucideIcons.heart,
                    color: comment.isLiked ? const Color(0xFFFF2A55) : Colors.white54,
                    size: 14,
                  ),
                  if (comment.likesCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${comment.likesCount}',
                      style: TextStyle(
                        color: comment.isLiked ? const Color(0xFFFF2A55) : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Comment Options Menu (Reply, Copy, Share, Delete only for Self) ────────
  void _showDesktopCommentOptionsMenu(
    CommentItem comment, {
    CommentItem? parentComment,
    required FeedPost post,
  }) {
    final comments = _getCommentsForPost(post);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    final currentUsername = currentUser?.name.toLowerCase() ?? 'alexj';

    // ── 3 Roles Allowed to Delete: 1) Owner of Post, 2) Author of Comment, 3) Admin ──
    final isPostOwner = (currentUser != null && currentUser.name.toLowerCase() == post.username.toLowerCase()) ||
        post.username.toLowerCase() == 'alexj';
    final isCommentAuthor = comment.isSelf ||
        (currentUser != null && comment.username.toLowerCase() == currentUsername);
    final isAdmin = currentUser != null &&
        (currentUser.email.toLowerCase().contains('admin') || currentUsername.contains('admin'));

    final canDelete = isPostOwner || isCommentAuthor || isAdmin;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CommentOptions',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  width: 310,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.28),
                      width: 1.2,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.22),
                        const Color(0xFF222B3D).withOpacity(0.55),
                        const Color(0xFF141926).withOpacity(0.65),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: const Color(0xFF54C5F8).withOpacity(0.14),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Snippet Header Pill
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.22)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 13, backgroundImage: NetworkImage(comment.avatarUrl)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '@${comment.username}: ${comment.text}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildReelCommentOptionTile(
                        icon: LucideIcons.reply,
                        title: 'Reply to @${comment.username}',
                        color: const Color(0xFF54C5F8),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _desktopReplyingTo = comment.username;
                            _desktopReplyingToComment = parentComment ?? comment;
                          });
                          _desktopCommentFocusNode.requestFocus();
                        },
                      ),
                      _buildReelCommentOptionTile(
                        icon: LucideIcons.copy,
                        title: 'Copy text',
                        onTap: () {
                          Navigator.pop(ctx);
                          Clipboard.setData(ClipboardData(text: comment.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Comment copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      _buildReelCommentOptionTile(
                        icon: LucideIcons.share2,
                        title: 'Share comment',
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Comment link copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      if (canDelete) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Divider(color: Colors.white.withOpacity(0.12), height: 1),
                        ),
                        _buildReelCommentOptionTile(
                          icon: LucideIcons.trash2,
                          title: 'Delete comment',
                          color: const Color(0xFFFF5252),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              if (parentComment != null) {
                                parentComment.replies.removeWhere((r) => r.id == comment.id);
                              } else {
                                comments.removeWhere((c) => c.id == comment.id);
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comment deleted'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _buildReelCommentOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white, size: 17),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Floating Action Bar Gesture Handlers (Hold & Drag over Media) ──────────
  void _startQuickActions(
    FeedPost post,
    LongPressStartDetails details,
    Size containerSize,
  ) {
    final barWidth = (containerSize.width - 24).clamp(280.0, 360.0);
    const barHeight = 70.0;
    final left = (details.localPosition.dx - barWidth / 2)
        .clamp(8.0, (containerSize.width - barWidth - 8).clamp(8.0, containerSize.width));
    final top = (details.localPosition.dy - barHeight - 24)
        .clamp(8.0, (containerSize.height - barHeight - 8).clamp(8.0, containerSize.height));

    setState(() {
      _activeActionPostId = post.id;
      _activeActionIndex = 2; // Default to heart
      _activeActionBarWidth = barWidth;
      _actionBarPosition = Offset(left, top);
      _actionTouchPosition = details.localPosition;
    });
  }

  void _updateQuickActions(LongPressMoveUpdateDetails details) {
    if (_activeActionBarWidth == 0) return;
    final itemWidth = _activeActionBarWidth / 6;
    final index =
        ((details.localPosition.dx - _actionBarPosition.dx) / itemWidth)
            .floor();

    setState(() {
      _actionTouchPosition = details.localPosition;
      _activeActionIndex = index.clamp(0, 5);
    });
  }

  void _finishQuickActions(FeedPost post) {
    if (_activeActionPostId == null) return;
    final actionIdx = _activeActionIndex;
    setState(() => _activeActionPostId = null);
    _executeQuickAction(post, actionIdx);
  }

  void _executeQuickAction(FeedPost post, int index) {
    switch (index) {
      case 0: // Comment
        setState(() {
          _desktopCommentsOpen = true;
          _reelsCoveredPostId = post.id;
          _reelsCoveredShowsComments = true;
          _isFullScreenModalOpen = true;
        });
        break;
      case 1: // Share
        Clipboard.setData(ClipboardData(text: 'https://codesnap.dev/post/${post.id}'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post link copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case 2: // Like
        _toggleLike(post);
        break;
      case 3: // Save
        _toggleSave(post);
        break;
      case 4: // Download
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading high-res media...'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case 5: // More / Description
        setState(() {
          _desktopDescriptionOpen = true;
          _reelsCoveredPostId = post.id;
          _reelsCoveredShowsComments = false;
          _isFullScreenModalOpen = true;
        });
        break;
    }
  }


  // ── Desktop Compact Left-Aligned Description Pill ──────────────────────────
  Widget _buildDesktopCompactDescription(FeedPost post) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _desktopDescriptionOpen = true;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.captionTitle,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SpringButton(
                      onTap: () {
                        setState(() {
                          _desktopDescriptionOpen = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF54C5F8).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF54C5F8).withOpacity(0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Details',
                              style: TextStyle(
                                color: Color(0xFF54C5F8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(LucideIcons.chevronUp, color: Color(0xFF54C5F8), size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  post.captionBody,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 12,
                    height: 1.35,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.music, color: Color(0xFF54C5F8), size: 11),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${post.musicTitle} • ${post.musicArtist}',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10.5),
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
      ),
    );
  }

  // ── Desktop Floating Actions (Like, Comments, Details, Save) ───────────────
  Widget _buildDesktopFloatingActions(FeedPost post) {
    final isLiked = _likedPostIds.contains(post.id);
    final isSaved = _savedPostIds.contains(post.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDesktopActionButton(
          icon: isLiked ? Icons.favorite : LucideIcons.heart,
          color: isLiked ? const Color(0xFFFF2A55) : Colors.white,
          label: '${post.likesCount + (isLiked ? 1 : 0)}',
          onTap: () => _toggleLike(post),
        ),
        const SizedBox(height: 12),
        _buildDesktopActionButton(
          icon: LucideIcons.messageCircle,
          color: Colors.white,
          label: 'Comments',
          onTap: () {
            setState(() {
              _desktopCommentsOpen = true;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildDesktopActionButton(
          icon: LucideIcons.fileText,
          color: Colors.white,
          label: 'Details',
          onTap: () {
            setState(() {
              _desktopDescriptionOpen = true;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildDesktopActionButton(
          icon: isSaved ? Icons.bookmark : LucideIcons.bookmark,
          color: isSaved ? const Color(0xFF54C5F8) : Colors.white,
          label: 'Save',
          onTap: () => _toggleSave(post),
        ),
      ],
    );
  }

  Widget _buildDesktopActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return SpringButton(
      onTap: onTap,
      scale: 0.90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
