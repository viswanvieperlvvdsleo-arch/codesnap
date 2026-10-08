import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../utils/app_animations.dart';
import '../utils/feed_mock_data.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_data_service.dart';
import 'spring_button.dart';

enum UIMode { snippet, cardRow, fullScreen }

class CommentItem {
  final String id;
  final String username;
  final String avatarUrl;
  final String text;
  final String timestamp;
  int likesCount;
  bool isLiked;
  final bool isSelf;
  final String? replyTo;
  final List<CommentItem> replies;

  CommentItem({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.text,
    required this.timestamp,
    this.likesCount = 0,
    this.isLiked = false,
    this.isSelf = false,
    this.replyTo,
    List<CommentItem>? replies,
  }) : replies = replies ?? [];
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class InteractiveBottomCards extends StatefulWidget {
  final FeedPost post;
  final bool isSaved;
  final VoidCallback onSaveToggled;
  final VoidCallback onShowDescription;
  final UIMode initialMode;
  final int initialPageIndex;
  final ValueChanged<UIMode>? onModeChanged;

  const InteractiveBottomCards({
    super.key,
    required this.post,
    required this.isSaved,
    required this.onSaveToggled,
    required this.onShowDescription,
    this.initialMode = UIMode.snippet,
    this.initialPageIndex = 0,
    this.onModeChanged,
  });

  @override
  State<InteractiveBottomCards> createState() => _InteractiveBottomCardsState();
}

class _InteractiveBottomCardsState extends State<InteractiveBottomCards> {
  late UIMode _mode;

  void _changeMode(UIMode newMode) {
    if (_mode != newMode) {
      setState(() => _mode = newMode);
      widget.onModeChanged?.call(newMode);
    }
  }

  // Card Row Focus: 0 = Description, 1 = Music, 2 = More
  int _focusedCardIndex = 0;

  // Full Screen Pager
  late PageController _pageController;
  int _fullScreenPageIndex = 0; // 0 = Description, 1 = Comments

  // Real-time Hand-Tracking Vertical Drag for dismiss / morph
  double _verticalDismissY = 0.0;
  bool _isDraggingDismiss = false;

  // Real-time Hand-Tracking Horizontal Drag for Page morph
  double _fullScreenHDrag = 0.0;

  // CardRow Drag state
  bool _isDraggingHorizontal = false;
  double _horizontalDragOffset = 0.0;

  late List<CommentItem> _comments;
  final Set<String> _expandedCommentIds = {};
  CommentItem? _replyingToComment;
  final TextEditingController _commentTextController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _fullScreenPageIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: widget.initialPageIndex);

    _comments = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLiveComments();
    });
  }

  bool _isLoadingComments = false;

  Future<void> _loadLiveComments() async {
    if (!mounted) return;
    setState(() => _isLoadingComments = true);
    try {
      final data = await SupabaseDataService.fetchComments(widget.post.id);
      if (!mounted) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = auth.currentUser?.id;

      final loaded = data.map((item) {
        final profile = item['profiles'] as Map<String, dynamic>?;
        final uname = profile?['username'] ?? profile?['full_name'] ?? 'developer';
        final avatar = (profile?['avatar_url'] != null && (profile!['avatar_url'] as String).isNotEmpty)
            ? profile['avatar_url'] as String
            : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80';
        final isSelf = (item['user_id'] != null && item['user_id'] == currentUserId);

        final createdAt = item['created_at'] != null
            ? DateTime.tryParse(item['created_at'].toString())
            : null;
        String timeStr = 'Just now';
        if (createdAt != null) {
          final diff = DateTime.now().difference(createdAt);
          if (diff.inDays > 0) {
            timeStr = '${diff.inDays}d';
          } else if (diff.inHours > 0) {
            timeStr = '${diff.inHours}h';
          } else if (diff.inMinutes > 0) {
            timeStr = '${diff.inMinutes}m';
          }
        }

        return CommentItem(
          id: item['id'].toString(),
          username: uname,
          avatarUrl: avatar,
          text: item['content'] ?? '',
          timestamp: timeStr,
          likesCount: 0,
          isLiked: false,
          isSelf: isSelf,
        );
      }).toList();

      setState(() {
        _comments = loaded;
        _isLoadingComments = false;
      });
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentTextController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InteractiveBottomCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMode != oldWidget.initialMode ||
        widget.initialPageIndex != oldWidget.initialPageIndex) {
      if (widget.initialMode == UIMode.fullScreen) {
        setState(() {
          _mode = UIMode.fullScreen;
          _verticalDismissY = 0;
          _fullScreenPageIndex = widget.initialPageIndex;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(widget.initialPageIndex);
          }
        });
      } else if (oldWidget.initialMode == UIMode.fullScreen &&
          widget.initialMode != UIMode.fullScreen) {
        setState(() {
          _mode = widget.initialMode;
        });
      }
    }
  }

  // --- Liquid Glass Builder ---
  Widget _buildGlass({
    required Widget child,
    double opacity = 0.08,
    double radius = 24,
    double blur = 8.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(opacity * 1.15),
                Colors.white.withOpacity(opacity * 0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.20), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // --- Page Switcher with Morph Animation ---
  void _animateToPage(int page) {
    if (_fullScreenPageIndex != page) {
      setState(() => _fullScreenPageIndex = page);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  // --- Gestures for Card Row ---
  void _onHorizontalDragStart(DragStartDetails details) {
    if (_mode == UIMode.cardRow) {
      setState(() {
        _isDraggingHorizontal = true;
        _horizontalDragOffset = 0.0;
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_mode == UIMode.cardRow) {
      setState(() {
        _horizontalDragOffset += details.delta.dx;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_mode != UIMode.cardRow) return;

    double totalW = MediaQuery.of(context).size.width - 28;
    double maxW = totalW - (64.0 + 8) * 2;
    double maxDelta = maxW - 64.0;
    double threshold = maxDelta * 0.35;

    int newIndex = _focusedCardIndex;

    if (_focusedCardIndex == 0 && _horizontalDragOffset < -threshold) {
      newIndex = 1;
    } else if (_focusedCardIndex == 1 && _horizontalDragOffset > threshold) {
      newIndex = 0;
    } else if (_focusedCardIndex == 1 && _horizontalDragOffset < -threshold) {
      newIndex = 2;
    } else if (_focusedCardIndex == 2 && _horizontalDragOffset > threshold) {
      newIndex = 1;
    }

    if (details.primaryVelocity != null) {
      if (details.primaryVelocity! < -400) {
        if (_focusedCardIndex < 2) newIndex = _focusedCardIndex + 1;
      } else if (details.primaryVelocity! > 400) {
        if (_focusedCardIndex > 0) newIndex = _focusedCardIndex - 1;
      }
    }

    setState(() {
      _isDraggingHorizontal = false;
      _focusedCardIndex = newIndex;
      _horizontalDragOffset = 0.0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_mode == UIMode.snippet) {
      if (details.primaryVelocity != null && details.primaryVelocity! < -250) {
        _changeMode(UIMode.cardRow);
      }
    } else if (_mode == UIMode.cardRow) {
      if (details.primaryVelocity != null) {
        if (details.primaryVelocity! < -250) {
          // Swipe UP on Card Row -> open Full Screen
          _changeMode(UIMode.fullScreen);
          _fullScreenPageIndex = 0;
          _verticalDismissY = 0;
          if (_pageController.hasClients) _pageController.jumpToPage(0);
        } else if (details.primaryVelocity! > 250) {
          // Swipe DOWN on Card Row -> go to Snippet
          _changeMode(UIMode.snippet);
        }
      }
    }
  }

  // --- Snippet UI ---
  Widget _buildSnippet() {
    String caption = widget.post.captionBody;
    if (caption.length > 35) caption = '${caption.substring(0, 35)}...';

    return Align(
      alignment: Alignment.bottomLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _changeMode(UIMode.cardRow),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          child: _buildGlass(
            opacity: 0.08,
            radius: 16,
            blur: 7.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                caption,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Card Row UI (Horizontal Morphing) ---
  Widget _buildCardRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalW = (constraints.maxWidth - 28).clamp(240.0, 1200.0);
        const double shrunkW = 64.0;
        const double gap = 8.0;

        // Subtract safe buffer of 2.0 to eliminate subpixel 0.0000244 / 0.0115px overflow
        final double maxWDesc  = (totalW - shrunkW - gap - 2.0).floorToDouble();
        final double maxWMusic = (totalW - shrunkW * 2 - gap * 2 - 2.0).floorToDouble();
        final double maxWMore  = (totalW - shrunkW - gap - 2.0).floorToDouble();

        double wDesc  = _focusedCardIndex == 0 ? maxWDesc  : (_focusedCardIndex == 1 ? shrunkW : 0);
        double wMusic = _focusedCardIndex == 0 ? shrunkW   : (_focusedCardIndex == 1 ? maxWMusic : shrunkW);
        double wMore  = _focusedCardIndex == 0 ? 0         : (_focusedCardIndex == 1 ? shrunkW : maxWMore);

        double hDesc  = _focusedCardIndex == 0 ? 110.0 : 64.0;
        double hMusic = _focusedCardIndex == 1 ? 110.0 : 64.0;
        double hMore  = _focusedCardIndex == 2 ? 110.0 : 64.0;

        if (_isDraggingHorizontal && _horizontalDragOffset != 0) {
          double shift = _horizontalDragOffset;
          double maxWDescDelta  = maxWDesc  - shrunkW;
          double maxWMoreDelta  = maxWMore  - shrunkW;

          if (_focusedCardIndex == 0 && shift < 0) {
            double amt = (-shift).clamp(0.0, maxWDescDelta);
            double hAmt = amt * (46.0 / maxWDescDelta);
            wDesc -= amt; wMusic += amt;
            hDesc -= hAmt; hMusic += hAmt;
          } else if (_focusedCardIndex == 1 && shift > 0) {
            double amt = shift.clamp(0.0, maxWDescDelta);
            double hAmt = amt * (46.0 / maxWDescDelta);
            wMusic -= amt; wDesc += amt;
            hMusic -= hAmt; hDesc += hAmt;
          } else if (_focusedCardIndex == 1 && shift < 0) {
            double amt = (-shift).clamp(0.0, maxWMoreDelta);
            double hAmt = amt * (46.0 / maxWMoreDelta);
            wMusic -= amt; wMore += amt;
            hMusic -= hAmt; hMore += hAmt;
          } else if (_focusedCardIndex == 2 && shift > 0) {
            double amt = shift.clamp(0.0, maxWMoreDelta);
            double hAmt = amt * (46.0 / maxWMoreDelta);
            wMore -= amt; wMusic += amt;
            hMore -= hAmt; hMusic += hAmt;
          }
        }

        Duration currentDuration = _isDraggingHorizontal ? Duration.zero : AppAnimations.standard;

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: _onVerticalDragEnd,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: SizedBox(
              height: 110,
              child: ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (wDesc > 0)
                        GestureDetector(
                          onTap: () {
                            _changeMode(UIMode.fullScreen);
                            _fullScreenPageIndex = 0;
                            _verticalDismissY = 0;
                            if (_pageController.hasClients) _pageController.jumpToPage(0);
                          },
                          child: AnimatedContainer(
                            duration: currentDuration,
                            curve: Curves.easeOutCubic,
                            width: wDesc,
                            height: hDesc,
                            child: _buildGlass(
                              opacity: 0.08,
                              child: ClipRect(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: (wDesc > 150 && hDesc > 80)
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.post.captionTitle,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Expanded(
                                              child: Text(
                                                widget.post.captionBody,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.85),
                                                  fontSize: 12,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                _buildAvatarGroup(),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    widget.post.likesCount > 0 ? '${widget.post.likesCount} ${widget.post.likesCount == 1 ? "like" : "likes"}' : 'No likes yet',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.7),
                                                      fontSize: 10,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Icon(LucideIcons.chevronRight,
                                                    color: Colors.white.withOpacity(0.7), size: 14),
                                              ],
                                            )
                                          ],
                                        )
                                      : const Center(child: Icon(LucideIcons.alignLeft, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (wDesc > 0) const SizedBox(width: gap),

                      if (wMusic > 0)
                        AnimatedContainer(
                          duration: currentDuration,
                          curve: Curves.easeOutCubic,
                          width: wMusic,
                          height: hMusic,
                          child: _buildGlass(
                            opacity: 0.08,
                            child: ClipRect(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: (wMusic > 150 && hMusic > 80)
                                    ? Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              widget.post.musicCoverUrl,
                                              width: 72, height: 72, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 72, height: 72,
                                                color: Colors.white10,
                                                child: const Icon(LucideIcons.music, color: Colors.white38),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  widget.post.musicTitle,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  widget.post.musicArtist,
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Center(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            widget.post.musicCoverUrl,
                                            width: 44, height: 44, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 44, height: 44,
                                              color: Colors.white10,
                                              child: const Icon(LucideIcons.music, color: Colors.white38, size: 20),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      if (wMore > 0 && wMusic > 0) const SizedBox(width: gap),

                      if (wMore > 0)
                        GestureDetector(
                          onTap: widget.onSaveToggled,
                          child: AnimatedContainer(
                            duration: currentDuration,
                            curve: Curves.easeOutCubic,
                            width: wMore,
                            height: hMore,
                            child: _buildGlass(
                              opacity: widget.isSaved ? 0.16 : 0.08,
                              child: ClipRect(
                                child: (wMore > 120 && hMore > 80)
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            widget.isSaved
                                                ? LucideIcons.bookmarkCheck
                                                : LucideIcons.bookmark,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.isSaved ? 'Saved' : 'Save',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Center(
                                        child: Icon(
                                          widget.isSaved
                                              ? LucideIcons.bookmarkCheck
                                              : LucideIcons.bookmark,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarGroup() {
    final avatars = widget.post.likedByAvatars;
    if (avatars.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < avatars.length.clamp(0, 3); i++)
          Align(
            widthFactor: 0.65,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 1.2),
              ),
              child: CircleAvatar(
                radius: 10,
                backgroundImage: NetworkImage(avatars[i]),
              ),
            ),
          ),
      ],
    );
  }

  // --- Full Screen Overlays with Hand-Movement Morphing & Horizontal Swipe ---
  Widget _buildFullScreen() {
    final double currentDismiss = _verticalDismissY;
    final double scaleRatio = (1.0 - (currentDismiss / 1400.0)).clamp(0.90, 1.0);
    final double glassOpacity = (0.06 * (1.0 - currentDismiss / 350.0)).clamp(0.02, 0.06);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
      color: Colors.black.withOpacity((0.04 * (1.0 - currentDismiss / 400.0)).clamp(0.0, 0.04)),
      child: AnimatedContainer(
        duration: _isDraggingDismiss ? Duration.zero : AppAnimations.standard,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, currentDismiss, 0)..scale(scaleRatio),
        child: _buildGlass(
          opacity: glassOpacity,
          radius: 28,
          blur: 7.0,
          child: SafeArea(
            child: Column(
              children: [
                // ── Top Header & Interactive Hand Drag Area ───────────────────
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (_) {
                    setState(() => _isDraggingDismiss = true);
                  },
                  onVerticalDragUpdate: (d) {
                    if (d.delta.dy > 0 || _verticalDismissY > 0) {
                      setState(() {
                        _verticalDismissY = (_verticalDismissY + d.delta.dy).clamp(0.0, 450.0);
                      });
                    }
                  },
                  onVerticalDragEnd: (d) {
                    _isDraggingDismiss = false;
                    final vel = d.primaryVelocity ?? 0;
                    if (_verticalDismissY > 75 || vel > 250) {
                      // Hand movement dismiss: morphs back down!
                      _changeMode(UIMode.snippet);
                      _verticalDismissY = 0;
                    } else {
                      // Spring back to top
                      setState(() {
                        _verticalDismissY = 0;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        // Hand Drag Handle
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title Bar with Mode Capsule & Close Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Interactive Fluid Morphing Segmented Switch
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0x26FFFFFF)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _animateToPage(0),
                                    child: AnimatedContainer(
                                      duration: AppAnimations.quick,
                                      curve: AppAnimations.snappy,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _fullScreenPageIndex == 0 ? const Color(0x38FFFFFF) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: _fullScreenPageIndex == 0 ? Border.all(color: const Color(0x33FFFFFF)) : null,
                                      ),
                                      child: Text(
                                        'Story',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: _fullScreenPageIndex == 0 ? FontWeight.w800 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _animateToPage(1),
                                    child: AnimatedContainer(
                                      duration: AppAnimations.quick,
                                      curve: AppAnimations.snappy,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _fullScreenPageIndex == 1 ? const Color(0x38FFFFFF) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: _fullScreenPageIndex == 1 ? Border.all(color: const Color(0x33FFFFFF)) : null,
                                      ),
                                      child: Text(
                                        'Comments (${widget.post.commentsCount})',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: _fullScreenPageIndex == 1 ? FontWeight.w800 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Close Button
                            SpringButton(
                              onTap: () => _changeMode(UIMode.snippet),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Swipeable & Morphing Content (Description <-> Comments) ──
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const _AppScrollBehavior(),
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _fullScreenPageIndex = index);
                      },
                      children: [
                        _buildFullDescription(),
                        _buildCommentsList(),
                      ],
                    ),
                  ),
                ),

                // ── Page Indicator (Interactive Fluid Dots) ───────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 18, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _animateToPage(0),
                        child: _buildDot(_fullScreenPageIndex == 0),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _animateToPage(1),
                        child: _buildDot(_fullScreenPageIndex == 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: AppAnimations.quick,
      curve: Curves.easeOutCubic,
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildFullDescription() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.captionTitle,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.post.captionBody,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.95),
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentOptionsMenu(CommentItem comment, {CommentItem? parentComment}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    final currentUsername = currentUser?.name.toLowerCase() ?? 'alexj';

    // ── 3 Roles Allowed to Delete: 1) Owner of Post, 2) Author of Comment, 3) Admin ──
    final isPostOwner = (currentUser != null && currentUser.name.toLowerCase() == widget.post.username.toLowerCase()) ||
        widget.post.username.toLowerCase() == 'alexj';
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
                                '"${comment.text}"',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCommentOptionTile(
                        icon: LucideIcons.reply,
                        title: 'Reply to @${comment.username}',
                        color: const Color(0xFF54C5F8),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _replyingToComment = parentComment ?? comment;
                            _replyingToUsername = comment.username;
                          });
                          _commentFocusNode.requestFocus();
                        },
                      ),
                      _buildCommentOptionTile(
                        icon: LucideIcons.copy,
                        title: 'Copy text',
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Comment copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      _buildCommentOptionTile(
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
                        _buildCommentOptionTile(
                          icon: LucideIcons.trash2,
                          title: 'Delete comment',
                          color: const Color(0xFFFF5252),
                          onTap: () {
                            Navigator.pop(ctx);
                            _deleteComment(comment, parentComment: parentComment);
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

  Widget _buildCommentOptionTile({
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

  void _deleteComment(CommentItem comment, {CommentItem? parentComment}) {
    setState(() {
      if (parentComment != null) {
        parentComment.replies.removeWhere((r) => r.id == comment.id);
      } else {
        _comments.removeWhere((c) => c.id == comment.id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment deleted'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildSingleCommentRow(CommentItem comment, {CommentItem? parentComment, bool isReply = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showCommentOptionsMenu(comment, parentComment: parentComment),
      child: Padding(
        padding: EdgeInsets.only(bottom: isReply ? 8 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: isReply ? 12 : 16,
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
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              color: Color(0xFF54C5F8),
                              fontSize: 8.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        comment.timestamp,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: isReply ? 9.5 : 10.5,
                        ),
                      ),
                    ],
                  ),
                  if (comment.replyTo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Replying to @${comment.replyTo}',
                      style: const TextStyle(
                        color: Color(0xFF54C5F8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    comment.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isReply ? 12 : 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Reply button (NO direct delete button: long press brings up options)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyingToComment = parentComment ?? comment;
                        _replyingToUsername = comment.username;
                      });
                      _commentFocusNode.requestFocus();
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Like comment button with count
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
                    size: isReply ? 12 : 14,
                  ),
                  if (comment.likesCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${comment.likesCount}',
                      style: TextStyle(
                        color: comment.isLiked ? const Color(0xFFFF2A55) : Colors.white54,
                        fontSize: isReply ? 10 : 11,
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

  Widget _buildCommentsList() {
    int totalCount = _comments.fold(0, (sum, c) => sum + 1 + c.replies.length);

    return Column(
      children: [
        // Header Row: Comments (count)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                'Comments',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Text(
                  '$totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Comments List with Nested Replies & "View replies"
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Text(
                    'No comments yet. Be the first to share!',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    final isExpanded = _expandedCommentIds.contains(comment.id);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSingleCommentRow(comment),
                        // "View replies" / "Hide replies" option
                        if (comment.replies.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedCommentIds.remove(comment.id);
                                } else {
                                  _expandedCommentIds.add(comment.id);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 42, bottom: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 1,
                                    color: Colors.white24,
                                    margin: const EdgeInsets.only(right: 8),
                                  ),
                                  Text(
                                    isExpanded
                                        ? 'Hide replies'
                                        : 'View ${comment.replies.length} ${comment.replies.length == 1 ? 'reply' : 'replies'}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                    size: 12,
                                    color: Colors.white60,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(left: 36, bottom: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: comment.replies.map((reply) {
                                  return _buildSingleCommentRow(
                                    reply,
                                    parentComment: comment,
                                    isReply: true,
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                ),
        ),

        // Replying To Banner
        if (_replyingToUsername != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.reply, size: 12, color: Color(0xFF54C5F8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Replying to @$_replyingToUsername',
                    style: const TextStyle(
                      color: Color(0xFF54C5F8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _replyingToUsername = null;
                    _replyingToComment = null;
                  }),
                  child: const Icon(LucideIcons.x, size: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

        // Comment Input Box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(
                  context.watch<AuthProvider>().currentUser?.avatarUrl.isNotEmpty == true
                      ? context.watch<AuthProvider>().currentUser!.avatarUrl
                      : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: TextField(
                    controller: _commentTextController,
                    focusNode: _commentFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: _replyingToUsername != null
                          ? 'Reply to @$_replyingToUsername...'
                          : 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SpringButton(
                onTap: _submitComment,
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
        ),
      ],
    );
  }

  void _submitComment() async {
    final text = _commentTextController.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final String currentUname = (user?.section?.isNotEmpty == true)
        ? user!.section!
        : (user?.name ?? 'You');
    final currentAvatar = (user?.avatarUrl?.isNotEmpty == true)
        ? user!.avatarUrl
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80';

    final newComment = CommentItem(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      username: currentUname,
      avatarUrl: currentAvatar,
      text: text,
      timestamp: 'Just now',
      likesCount: 0,
      isLiked: false,
      isSelf: true,
      replyTo: _replyingToUsername,
    );

    setState(() {
      if (_replyingToComment != null) {
        _replyingToComment!.replies.add(newComment);
        _expandedCommentIds.add(_replyingToComment!.id);
      } else {
        _comments.insert(0, newComment);
      }
      _commentTextController.clear();
      _replyingToUsername = null;
      _replyingToComment = null;
    });

    try {
      await SupabaseDataService.addComment(
        postId: widget.post.id,
        content: text,
        userId: user?.id,
      );
    } catch (e) {
      debugPrint('Error saving comment to Supabase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppAnimations.expressive,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: () {
        if (_mode == UIMode.snippet) return _buildSnippet();
        if (_mode == UIMode.cardRow) return _buildCardRow();
        return _buildFullScreen();
      }(),
    );
  }
}
