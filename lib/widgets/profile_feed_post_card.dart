import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/saved_posts_manager.dart';
import '../services/supabase_data_service.dart';
import '../utils/feed_mock_data.dart';
import 'floating_action_bar.dart' as quick_actions;
import 'full_screen_image_viewer.dart';
import 'interactive_bottom_cards.dart';
import 'morphing_capsule.dart';
import 'swipe_action_bar.dart';

/// The same visual and interaction model used by Home feed posts, packaged for
/// profile timelines so mobile and desktop render the same sized card.
class ProfileFeedPostCard extends StatefulWidget {
  final FeedPost post;
  final bool initiallyLiked;

  const ProfileFeedPostCard({
    super.key,
    required this.post,
    required this.initiallyLiked,
  });

  @override
  State<ProfileFeedPostCard> createState() => _ProfileFeedPostCardState();
}

class _ProfileFeedPostCardState extends State<ProfileFeedPostCard> {
  late bool _isLiked;
  late bool _isSaved;
  String? _activeActionPostId;
  int _activeActionIndex = 2;
  double _activeActionBarWidth = 360;
  Offset _actionBarPosition = Offset.zero;
  Offset _actionTouchPosition = Offset.zero;
  UIMode _mode = UIMode.snippet;
  int _fullScreenPage = 0;
  bool _savingLike = false;

  FeedPost get post => widget.post;
  bool get _hasMedia =>
      post.imageUrl.startsWith('https://') ||
      post.imageUrl.startsWith('http://') ||
      post.imageUrl.startsWith('data:image') ||
      post.imageUrl.startsWith('blob:');

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initiallyLiked;
    _isSaved = SavedPostsManager.isSaved(post.id);
  }

  Future<void> _toggleLike() async {
    if (_savingLike) return;
    final wasLiked = _isLiked;
    setState(() {
      _savingLike = true;
      _isLiked = !wasLiked;
      post.likesCount =
          (post.likesCount + (wasLiked ? -1 : 1)).clamp(0, 1 << 31);
    });
    try {
      final saved = await SupabaseDataService.togglePostLike(post.id);
      if (!mounted) return;
      if (saved != _isLiked) {
        setState(() {
          post.likesCount =
              (post.likesCount + (saved ? 1 : -1)).clamp(0, 1 << 31);
          _isLiked = saved;
        });
      }
      MorphingCapsule.show(
        context,
        icon: saved ? LucideIcons.heart : LucideIcons.heartCrack,
        label: saved ? 'Liked!' : 'Unliked',
        color: saved ? Colors.redAccent : Colors.white70,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        post.likesCount =
            (post.likesCount + (wasLiked ? 1 : -1)).clamp(0, 1 << 31);
        _isLiked = wasLiked;
      });
      _toast('Could not update like', LucideIcons.triangleAlert,
          const Color(0xFFFF5252));
    } finally {
      if (mounted) setState(() => _savingLike = false);
    }
  }

  void _toggleSave() {
    final saved = SavedPostsManager.toggleSave(post);
    setState(() => _isSaved = saved);
    _toast(
      saved ? 'Saved to Saved List!' : 'Removed from Saved',
      saved ? LucideIcons.bookmarkCheck : LucideIcons.bookmarkMinus,
      const Color(0xFFFFD700),
    );
  }

  void _showDetails({bool comments = false}) {
    setState(() {
      _mode = UIMode.fullScreen;
      _fullScreenPage = comments ? 1 : 0;
    });
  }

  Future<void> _share() async {
    await Clipboard.setData(
      ClipboardData(text: 'https://codesnap.dev/post/${post.id}'),
    );
    if (mounted) {
      _toast('Post link copied', LucideIcons.send, const Color(0xFF54C5F8));
    }
  }

  Future<void> _download() async {
    if (!_hasMedia) {
      _toast('This post has no downloadable media', LucideIcons.imageOff,
          Colors.white70);
      return;
    }
    try {
      final uri = Uri.tryParse(post.imageUrl);
      final lastSegment =
          uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : '';
      final rawExtension = lastSegment.contains('.')
          ? lastSegment.split('.').last.toLowerCase()
          : 'jpg';
      final extension = RegExp(r'^[a-z0-9]{2,5}$').hasMatch(rawExtension)
          ? rawExtension
          : 'jpg';
      await FileSaver.instance.downloadLink(
        link: LinkDetails(link: post.imageUrl),
        name: 'codesnap-${post.id}.$extension',
      );
      if (mounted) {
        _toast(
            'Download started', LucideIcons.download, const Color(0xFF10B981));
      }
    } catch (_) {
      if (mounted) {
        _toast('Download failed', LucideIcons.triangleAlert,
            const Color(0xFFFF5252));
      }
    }
  }

  void _toast(String label, IconData icon, Color color) {
    MorphingCapsule.show(context, icon: icon, label: label, color: color);
  }

  void _startQuickActions(LongPressStartDetails details, Size cardSize) {
    final width = (cardSize.width - 20).clamp(280.0, 360.0);
    const height = 70.0;
    final left = (details.localPosition.dx - width / 2)
        .clamp(8.0, (cardSize.width - width - 8).clamp(8.0, cardSize.width));
    final top = (details.localPosition.dy - height - 22)
        .clamp(8.0, cardSize.height - height - 8);
    setState(() {
      _activeActionPostId = post.id;
      _activeActionIndex =
          ((details.localPosition.dx - left) / (width / 6)).floor().clamp(0, 5);
      _activeActionBarWidth = width;
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

  void _finishQuickActions() => _executeQuickAction(_activeActionIndex);

  void _executeQuickAction(int index) {
    setState(() => _activeActionPostId = null);
    switch (index) {
      case 0:
        _showDetails(comments: true);
      case 1:
        _share();
      case 2:
        _toggleLike();
      case 3:
        _toggleSave();
      case 4:
        _download();
      case 5:
        _showDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 580;
        final cardWidth = isWide ? 510.0 : constraints.maxWidth;
        final aspectRatio = isWide ? (4.0 / 3.6) : (3.0 / 4.2);
        final cardHeight = cardWidth / aspectRatio;
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
                    ? const [
                        BoxShadow(
                          color: Color(0x59000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hasMedia
                    ? () => FullScreenImageViewer.show(
                          context,
                          imageUrl: post.imageUrl,
                          title: post.captionTitle,
                        )
                    : null,
                onDoubleTap: _toggleLike,
                onLongPressStart: (details) =>
                    _startQuickActions(details, cardSize),
                onLongPressMoveUpdate: _updateQuickActions,
                onLongPressEnd: (_) => _finishQuickActions(),
                onLongPressCancel: () =>
                    setState(() => _activeActionPostId = null),
                child: Stack(children: [
                  Positioned.fill(child: _media()),
                  const Positioned.fill(child: _TopGradient()),
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: _BottomGradient(),
                  ),
                  Positioned(top: 18, left: 14, right: 80, child: _author()),
                  Positioned(
                    top: 18,
                    right: 14,
                    child: SwipeActionBar(
                      isLiked: _isLiked,
                      likesCount: post.likesCount,
                      onLikeToggled: _toggleLike,
                    ),
                  ),
                  Positioned.fill(
                    child: InteractiveBottomCards(
                      post: post,
                      isSaved: _isSaved,
                      onSaveToggled: _toggleSave,
                      onShowDescription: _showDetails,
                      initialMode: _mode,
                      initialPageIndex: _fullScreenPage,
                      onModeChanged: (mode) {
                        if (_mode != mode) setState(() => _mode = mode);
                      },
                    ),
                  ),
                  if (_activeActionPostId == post.id)
                    quick_actions.FloatingActionBar(
                      position: _actionBarPosition,
                      touchPosition: _actionTouchPosition,
                      onActionSelected: _executeQuickAction,
                      onCancel: () =>
                          setState(() => _activeActionPostId = null),
                      commentsCount: post.commentsCount,
                      sharesCount: post.sharesCount,
                      width: _activeActionBarWidth,
                    ),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _media() {
    if (_hasMedia) {
      return Image.network(
        post.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _mediaFallback(),
      );
    }
    return _mediaFallback();
  }

  Widget _mediaFallback() => Container(
        color: const Color(0xFF111319),
        padding: const EdgeInsets.fromLTRB(24, 88, 24, 150),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Text(
            post.captionBody,
            style: const TextStyle(
              color: Color(0xFFD5D8E0),
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      );

  Widget _author() =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x4DFFFFFF), width: 1.5),
          ),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF24262D),
            foregroundImage:
                post.avatarUrl.isEmpty ? null : NetworkImage(post.avatarUrl),
            child: post.avatarUrl.isEmpty
                ? const Icon(LucideIcons.user, color: Colors.white70, size: 16)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(post.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.white, size: 13),
            ]),
            if (post.location.isNotEmpty)
              Row(children: [
                const Icon(LucideIcons.mapPin, color: Colors.white70, size: 11),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(post.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: const Color(0xB3FFFFFF), fontSize: 11)),
                ),
              ]),
          ]),
        ),
      ]);
}

class _TopGradient extends StatelessWidget {
  const _TopGradient();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(0, -.2),
            colors: [Color(0x99000000), Colors.transparent],
          ),
        ),
      );
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0x59000000), Colors.transparent],
          ),
        ),
      );
}
