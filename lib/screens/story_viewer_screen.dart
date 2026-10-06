import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/feed_mock_data.dart';
import '../widgets/spring_button.dart';

class StoryViewerScreen extends StatefulWidget {
  final FeedStory? story;
  final List<FeedStory>? allStories;
  final int initialStoryIndex;
  final VoidCallback? onCompleted;

  const StoryViewerScreen({
    super.key,
    this.story,
    this.allStories,
    this.initialStoryIndex = 0,
    this.onCompleted,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late List<FeedStory> _storiesList;
  late int _currentStoryIndex;
  int _currentSlideIndex = 0;

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  // Horizontal drag delta to detect swiping left/right to skip between users
  double _horizontalDragDelta = 0;

  FeedStory get _currentStory => _storiesList[_currentStoryIndex];
  List<FeedStoryItem> get _slides => _currentStory.items;
  FeedStoryItem get _currentSlide {
    if (_slides.isEmpty) {
      return FeedStoryItem(
        id: 'fallback',
        imageUrl: _currentStory.imageUrl,
        time: _currentStory.timeAgo,
      );
    }
    return _slides[_currentSlideIndex.clamp(0, _slides.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    if (widget.allStories != null && widget.allStories!.isNotEmpty) {
      _storiesList = List.from(widget.allStories!);
      _currentStoryIndex = widget.initialStoryIndex.clamp(0, _storiesList.length - 1);
    } else if (widget.story != null) {
      _storiesList = [widget.story!];
      _currentStoryIndex = 0;
    } else {
      _storiesList = [];
      _currentStoryIndex = 0;
    }

    if (_storiesList.isNotEmpty) {
      _currentStory.isViewed = true;
    }

    _initSlideTimer();

    _replyFocusNode.addListener(() {
      if (_replyFocusNode.hasFocus) {
        _progressController.stop();
      } else {
        _progressController.forward();
      }
    });
  }

  void _initSlideTimer() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextSlide();
        }
      });
    _progressController.forward();
  }

  void _nextSlide() {
    if (_slides.isNotEmpty && _currentSlideIndex < _slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      // Current user's stories all completed! Seamlessly advance to next user if available
      _nextStoryUser();
    }
  }

  void _prevSlide() {
    if (_currentSlideIndex > 0) {
      setState(() {
        _currentSlideIndex--;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      // If at first slide of current user, jump to previous user
      _prevStoryUser();
    }
  }

  void _nextStoryUser() {
    if (_currentStoryIndex < _storiesList.length - 1) {
      setState(() {
        _currentStory.isViewed = true;
        _currentStoryIndex++;
        _currentSlideIndex = 0;
        _currentStory.isViewed = true;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      _close();
    }
  }

  void _prevStoryUser() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _currentSlideIndex = 0;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _close() {
    if (_storiesList.isNotEmpty) {
      _currentStory.isViewed = true;
    }
    widget.onCompleted?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _toggleLike() {
    setState(() {
      _currentSlide.isLiked = !_currentSlide.isLiked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currentSlide.isLiked ? 'Liked story ❤️' : 'Unliked story'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendReaction(String emoji) {
    setState(() {
      _currentSlide.reactions.add(emoji);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reacted with $emoji to ${_currentStory.username}'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    _replyController.clear();
    _replyFocusNode.unfocus();
    _progressController.forward();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reply sent: "$text"'),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_storiesList.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('No stories', style: TextStyle(color: Colors.white70))),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width > 700;
    final slide = _currentSlide;
    final story = _currentStory;

    Widget storyCard = ClipRRect(
      borderRadius: isDesktop ? BorderRadius.circular(24) : BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          border: isDesktop ? Border.all(color: Colors.white.withOpacity(0.22), width: 1.2) : null,
          boxShadow: isDesktop
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.65),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ]
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background Story Media ───────────────────────────────────────
            Image.network(
              slide.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF181920),
                child: const Center(
                  child: Icon(LucideIcons.image, size: 60, color: Colors.white24),
                ),
              ),
            ),

            // Top Gradient & Bottom Gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 180,
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Tap zones: Left 35% taps previous, Right 65% taps next ────────
            Positioned(
              left: 0,
              top: 80,
              bottom: 120,
              width: isDesktop ? 140 : MediaQuery.of(context).size.width * 0.35,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _prevSlide,
              ),
            ),
            Positioned(
              right: 0,
              top: 80,
              bottom: 120,
              left: isDesktop ? 140 : MediaQuery.of(context).size.width * 0.35,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _nextSlide,
              ),
            ),

            // ── Desktop Navigation Chevrons (< and > buttons) ───────────────────
            if (isDesktop) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SpringButton(
                    onTap: _prevSlide,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.45),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SpringButton(
                    onTap: _nextSlide,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.45),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.chevronRight, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],

            // ── Top Header UI (Segmented Progress Bars, User Info, Close) ─────
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Segmented Progress Bars (one segment per slide)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: List.generate(_slides.length, (idx) {
                        double progressValue = 0.0;
                        if (idx < _currentSlideIndex) {
                          progressValue = 1.0;
                        } else if (idx == _currentSlideIndex) {
                          progressValue = _progressController.value;
                        } else {
                          progressValue = 0.0;
                        }

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            height: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                backgroundColor: Colors.white.withOpacity(0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // User Info Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        SpringButton(
                          onTap: _close,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 17,
                          backgroundImage: NetworkImage(story.imageUrl),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.username,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                slide.time ?? story.timeAgo,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(LucideIcons.moreVertical, color: Colors.white, size: 20),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                          onPressed: _close,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Caption (if any) ─────────────────────────────────────────────
            if (slide.caption != null && slide.caption!.isNotEmpty)
              Positioned(
                bottom: 85,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    slide.caption!,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // ── Clean Modern Chat-Style Reply Bar ────────────────────────────
            Positioned(
              bottom: 16,
              left: 14,
              right: 14,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Clean chat-style pill
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.only(left: 14, right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0x28FFFFFF), width: 1.0),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _replyController,
                                    focusNode: _replyFocusNode,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    cursorColor: const Color(0xFF54C5F8),
                                    decoration: InputDecoration(
                                      hintText: 'Reply to @${story.username}...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.55),
                                        fontSize: 12.5,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (_) => _sendReply(),
                                  ),
                                ),
                                SpringButton(
                                  onTap: _sendReply,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF54C5F8),
                                    ),
                                    child: const Icon(LucideIcons.send, color: Colors.black, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick emoji reaction
                    SpringButton(
                      onTap: () => _sendReaction('🔥'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x28FFFFFF)),
                            ),
                            child: const Text('🔥', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Heart / Like Button
                    SpringButton(
                      onTap: _toggleLike,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: slide.isLiked
                                  ? const Color(0xFFFF4864).withOpacity(0.25)
                                  : const Color(0x1AFFFFFF),
                              border: Border.all(
                                color: slide.isLiked
                                    ? const Color(0xFFFF4864)
                                    : const Color(0x28FFFFFF),
                              ),
                            ),
                            child: Icon(
                              slide.isLiked ? Icons.favorite : LucideIcons.heart,
                              color: slide.isLiked ? const Color(0xFFFF4864) : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── On Desktop: Ambient blurred background covering the full screen ──
          if (isDesktop) ...[
            Positioned.fill(
              child: Image.network(
                slide.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF09090B)),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  color: Colors.black.withOpacity(0.68),
                ),
              ),
            ),
          ],

          // ── Main Story Card (Mobile Aspect Ratio: Centered on Desktop) ───────
          Center(
            child: SizedBox(
              width: isDesktop ? 414 : double.infinity,
              height: isDesktop ? 760 : double.infinity,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: (_) => _progressController.stop(),
                onLongPressEnd: (_) {
                  if (!_replyFocusNode.hasFocus) _progressController.forward();
                },
                onHorizontalDragUpdate: (details) {
                  _horizontalDragDelta += details.delta.dx;
                },
                onHorizontalDragEnd: (details) {
                  if (_horizontalDragDelta < -40 ||
                      (details.primaryVelocity != null && details.primaryVelocity! < -250)) {
                    // Swiped right-to-left -> skip direct to next user story!
                    _nextStoryUser();
                  } else if (_horizontalDragDelta > 40 ||
                      (details.primaryVelocity != null && details.primaryVelocity! > 250)) {
                    // Swiped left-to-right -> skip direct to previous user story!
                    _prevStoryUser();
                  }
                  _horizontalDragDelta = 0;
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
                    _close();
                  }
                },
                child: storyCard,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
