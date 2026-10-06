import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../utils/app_animations.dart';
import '../providers/theme_provider.dart';

/// ─── SpringButton ────────────────────────────────────────────────────────────
/// Wraps any child with squash-and-stretch spring press interaction.
/// On press: scales down. On release: springs back with slight overshoot.
class SpringButton extends StatefulWidget {
  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = AppAnimations.pressScale,
    this.showGlow = false,
    this.glowColor,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool showGlow;
  final Color? glowColor;
  final BorderRadius borderRadius;

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  // Use unbounded controller so spring can overshoot past 0–1
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // No bounds — spring simulation handles its own range
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    _isPressed = true;
    // Animate to 1 (pressed state)
    _controller.animateTo(
      1.0,
      duration: AppAnimations.micro,
      curve: Curves.easeIn,
    );
  }

  void _release() {
    _isPressed = false;
    // Spring back with overshoot from current position
    final simulation = SpringSimulation(
      AppAnimations.bouncySpring,
      _controller.value,
      0.0,
      -8.0, // release velocity
    );
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final glowColor =
        widget.glowColor ?? ThemeProvider.primaryGold.withOpacity(0.4);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(_press),
      onTapUp: (_) {
        setState(_release);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(_release),
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Map 0→1 controller to 1.0→pressScale
          final scaleValue = 1.0 -
              (_controller.value.clamp(0.0, 1.0) *
                  (1.0 - widget.scale));

          return Transform.scale(
            scale: scaleValue,
            child: widget.showGlow && _isPressed
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor,
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: child,
                  )
                : child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
