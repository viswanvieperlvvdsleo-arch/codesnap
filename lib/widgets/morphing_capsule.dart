import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_animations.dart';
import '../providers/theme_provider.dart';

/// ─── MorphingCapsule ─────────────────────────────────────────────────────────
/// Live Alerts Capsule Morphing widget.
/// Starts as a small dot → springs open into a pill with icon + text.
/// Auto-dismisses after [displayDuration] unless [autoDismiss] is false.
///
/// Usage:
///   MorphingCapsule.show(context, icon: LucideIcons.heart, label: 'Liked!');
class MorphingCapsule extends StatefulWidget {
  const MorphingCapsule({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.displayDuration = const Duration(seconds: 2),
    this.onDismissed,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final Duration displayDuration;
  final VoidCallback? onDismissed;

  /// Show a capsule overlay on top of current screen
  static OverlayEntry show(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    Duration displayDuration = const Duration(seconds: 2),
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CapsuleOverlay(
        icon: icon,
        label: label,
        color: color ?? ThemeProvider.primaryGold,
        displayDuration: displayDuration,
        onDismissed: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<MorphingCapsule> createState() => _MorphingCapsuleState();
}

class _MorphingCapsuleState extends State<MorphingCapsule>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.overshoot,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _controller.animateTo(1.0,
        duration: AppAnimations.expressive,
        curve: AppAnimations.overshoot);

    // Auto dismiss
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _controller
            .animateTo(0.0,
                duration: AppAnimations.standard, curve: Curves.easeInCubic)
            .whenComplete(() => widget.onDismissed?.call());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? ThemeProvider.primaryGold;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 + 6 * _expandAnimation.value,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: color.withOpacity(0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: color, size: 18),
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      axis: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 7),
                          Text(
                            widget.label,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
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
      },
    );
  }
}

/// Internal overlay wrapper for positioning
class _CapsuleOverlay extends StatelessWidget {
  const _CapsuleOverlay({
    required this.icon,
    required this.label,
    required this.color,
    required this.displayDuration,
    required this.onDismissed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Duration displayDuration;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 0,
      right: 0,
      child: Center(
        child: MorphingCapsule(
          icon: icon,
          label: label,
          color: color,
          displayDuration: displayDuration,
          onDismissed: onDismissed,
        ),
      ),
    );
  }
}
