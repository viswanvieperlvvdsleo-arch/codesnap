import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/theme_provider.dart';
import '../utils/app_animations.dart';

class FloatingActionBarItem {
  final IconData icon;
  final String label;
  final String? count;

  FloatingActionBarItem({
    required this.icon,
    required this.label,
    this.count,
  });
}

class FloatingActionBar extends StatefulWidget {
  final Offset position;
  final Offset touchPosition;
  final ValueChanged<int> onActionSelected;
  final VoidCallback onCancel;
  final int commentsCount;
  final int sharesCount;
  final double width;

  const FloatingActionBar({
    super.key,
    required this.position,
    required this.touchPosition,
    required this.onActionSelected,
    required this.onCancel,
    required this.commentsCount,
    required this.sharesCount,
    this.width = 360,
  });

  @override
  State<FloatingActionBar> createState() => _FloatingActionBarState();
}

class _FloatingActionBarState extends State<FloatingActionBar>
    with TickerProviderStateMixin {
  late List<FloatingActionBarItem> items;
  int _selectedIndex = -1;
  final double _itemHeight = 70.0;
  // Subtract 2 pixels to account for the 1px border on each side of the Container, preventing overflow
  double get _itemWidth => (widget.width - 2) / items.length;

  // ── Biometric ripple entrance animation ──
  late AnimationController _rippleController;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  // ── Staggered item controllers ──
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemScales;
  late List<Animation<double>> _itemFades;

  @override
  void initState() {
    super.initState();

    items = [
      FloatingActionBarItem(
          icon: LucideIcons.messageCircle,
          label: 'Comment',
          count: _formatCount(widget.commentsCount)),
      FloatingActionBarItem(
          icon: LucideIcons.send,
          label: 'Share',
          count: _formatCount(widget.sharesCount)),
      FloatingActionBarItem(icon: LucideIcons.heart, label: 'Like'),
      FloatingActionBarItem(icon: LucideIcons.bookmark, label: 'Save'),
      FloatingActionBarItem(icon: LucideIcons.download, label: 'Download'),
      FloatingActionBarItem(icon: LucideIcons.ellipsis, label: 'More'),
    ];

    // ── Biometric ripple (radial scale-in from center) ──
    _rippleController = AnimationController(
      vsync: this,
      duration: AppAnimations.expressive,
    );
    _rippleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _rippleController, curve: AppAnimations.overshoot),
    );
    _rippleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _rippleController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    // ── Staggered item entrance ──
    _itemControllers = List.generate(
      items.length,
      (i) => AnimationController(
        vsync: this,
        duration: AppAnimations.standard,
      ),
    );
    _itemScales = _itemControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: AppAnimations.bounce)))
        .toList();
    _itemFades = _itemControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    // Launch ripple then stagger items
    _rippleController.forward();
    _launchStaggeredItems();
  }

  Future<void> _launchStaggeredItems() async {
    for (int i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(AppAnimations.stagger(i, baseMs: 45));
      if (mounted) _itemControllers[i].forward();
    }
  }

  @override
  void didUpdateWidget(FloatingActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.touchPosition != widget.touchPosition) {
      _calculateSelectedIndex();
    }
  }

  void _calculateSelectedIndex() {
    final localX = widget.touchPosition.dx - widget.position.dx;
    final localY = widget.touchPosition.dy - widget.position.dy;

    if (localY >= -30 &&
        localY <= _itemHeight + 30 &&
        localX >= -20 &&
        localX <= widget.width + 20) {
      int index = (localX / _itemWidth).floor();
      if (index >= 0 && index < items.length) {
        if (_selectedIndex != index) {
          setState(() => _selectedIndex = index);
        }
        return;
      }
    }

    if (_selectedIndex != -1) {
      setState(() => _selectedIndex = -1);
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    for (final c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.position.dy,
      left: widget.position.dx,
      child: AnimatedBuilder(
        animation: _rippleController,
        builder: (context, child) {
          return Opacity(
            opacity: _rippleOpacity.value,
            child: Transform.scale(
              scale: _rippleScale.value,
              child: child,
            ),
          );
        },
        child: Container(
          height: _itemHeight,
          width: widget.width,
          color: Colors.transparent, // Completely invisible background
          child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Sliding highlight indicator
                  if (_selectedIndex != -1)
                    AnimatedPositioned(
                      duration: AppAnimations.quick,
                      curve: AppAnimations.snappy,
                      left: _selectedIndex * _itemWidth,
                      top: 0,
                      child: Container(
                        width: _itemWidth,
                        height: _itemHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeProvider.primaryGold.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: ThemeProvider.primaryGold
                                      .withOpacity(0.4),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Staggered icon items
                  Row(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = _selectedIndex == index;

                      return AnimatedBuilder(
                        animation: _itemControllers[index],
                        builder: (context, _) {
                          return Opacity(
                            opacity: _itemFades[index].value,
                            child: Transform.scale(
                              scale: _itemScales[index].value,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => widget.onActionSelected(index),
                                child: SizedBox(
                                  width: _itemWidth,
                                  height: _itemHeight,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedScale(
                                        scale: isSelected ? 1.35 : 1.0, // Aggressively scale the icon when selected
                                        duration: AppAnimations.quick,
                                        curve: AppAnimations.bounce,
                                        child: AnimatedContainer(
                                          duration: AppAnimations.micro,
                                          child: Icon(
                                            item.icon,
                                            color: isSelected
                                                ? ThemeProvider.primaryGold
                                                : Colors.white,
                                            size: 26, // Slightly larger base size
                                          ),
                                        ),
                                      ),
                                      if (item.count != null) ...[
                                        const SizedBox(height: 4),
                                        AnimatedDefaultTextStyle(
                                          duration: AppAnimations.micro,
                                          style: TextStyle(
                                            color: isSelected
                                                ? ThemeProvider.primaryGold
                                                : Colors.white.withOpacity(0.8),
                                            fontSize: 10,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                          ),
                                          child: Text(item.count!),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
