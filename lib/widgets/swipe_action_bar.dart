import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/app_animations.dart';
import '../providers/theme_provider.dart';

class SwipeActionBar extends StatefulWidget {
  const SwipeActionBar({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.onLikeToggled,
  });

  final bool isLiked;
  final int likesCount;
  final VoidCallback onLikeToggled;

  @override
  State<SwipeActionBar> createState() => _SwipeActionBarState();
}

class _SwipeActionBarState extends State<SwipeActionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;
  int _hoveredIndex = -1;

  final List<IconData> _icons = [
    LucideIcons.messageCircle,
    LucideIcons.send,
    LucideIcons.heart, // Like button is at index 2
    LucideIcons.bookmark,
    LucideIcons.download,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.expressive,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() {
      _isExpanded = true;
      _hoveredIndex = 2; // Default to heart when holding
    });
    _controller.forward();
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    // Determine which icon we are hovering over.
    // The bar expands to the left. The heart is at the right edge initially,
    // but the full row is about 280px wide. Each icon is ~50px wide.
    // Local position from the right edge.
    final dx = details.localPosition.dx;
    // Assuming width is 280, icon width 56.
    // dx < 56 -> index 4
    // 56 - 112 -> index 3
    // 112 - 168 -> index 2
    // 168 - 224 -> index 1
    // 224 - 280 -> index 0

    // To make it robust, we'll calculate from the left of the expanded container.
    // We'll give each icon a 50px hit zone.
    int hover = (dx / 50).floor();
    if (hover < 0) hover = 0;
    if (hover > 4) hover = 4;

    if (_hoveredIndex != hover) {
      setState(() => _hoveredIndex = hover);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_hoveredIndex == 2) {
      widget.onLikeToggled();
    }
    setState(() {
      _isExpanded = false;
      _hoveredIndex = -1;
    });
    _controller.reverse();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onLikeToggled,
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final expandValue = CurvedAnimation(
                  parent: _controller, curve: AppAnimations.overshoot)
              .value;
          final width = 50.0 + (expandValue * 200.0);

          return SizedBox(
            width: width.clamp(50.0, 250.0),
            height: 60,
            child: Stack(
              alignment: Alignment.centerRight,
              children: List.generate(_icons.length, (index) {
                // If not expanded, only show index 2 (Heart).
                // When expanded, spread them out.
                // The heart (index 2) stays roughly in the same spot, others slide out to the left.
                // 0: Message, 1: Send, 2: Heart, 3: Save, 4: Download

                final isHeart = index == 2;
                final isHovered = _isExpanded && _hoveredIndex == index;

                // Position offset relative to the right edge
                // index 4 -> 0
                // index 3 -> 50
                // index 2 -> 100
                // index 1 -> 150
                // index 0 -> 200
                final targetRight = (4 - index) * 50.0;
                final opacity =
                    isHeart ? 1.0 : (_controller.value).clamp(0.0, 1.0);

                IconData iconData = _icons[index];
                if (isHeart && widget.isLiked) {
                  // Keep filled heart if liked
                  // Note: using the same icon but coloring it red
                }

                return Positioned(
                  right: isHeart ? 0 : targetRight * expandValue,
                  child: Opacity(
                    opacity: opacity,
                    child: AnimatedContainer(
                      duration: AppAnimations.quick,
                      curve: AppAnimations.snappy,
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isHovered
                            ? Colors.white.withOpacity(0.15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isHovered
                            ? Border.all(color: Colors.white.withOpacity(0.3))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            iconData,
                            color: isHeart && widget.isLiked
                                ? Colors.redAccent
                                : Colors.white,
                            size: isHovered ? 26 : 22,
                          ),
                          if (isHeart)
                            Text(
                              _formatCount(widget.likesCount),
                              style: TextStyle(
                                color: isHovered
                                    ? ThemeProvider.primaryGold
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
