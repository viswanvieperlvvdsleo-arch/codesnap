import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_animations.dart';

/// ─── Page Route Transitions ──────────────────────────────────────────────────

/// Scale + Fade transition — used for pushing new screens.
/// Outgoing page scales down and blurs. Incoming scales up from 0.92.
class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  ScaleFadePageRoute({required this.page, super.settings})
      : super(
          transitionDuration: AppAnimations.expressive,
          reverseTransitionDuration: AppAnimations.standard,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: _buildTransitions,
        );

  final Widget page;

  static Widget _buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Incoming: scale 0.92→1.0 with overshoot curve + fade
    final incomingScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: AppAnimations.expressiveEntrance),
    );
    final incomingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: animation, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    // Outgoing: scale 1.0→0.94 and blur
    final outgoingScale =
        Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: AppAnimations.decelerate),
    );

    return Stack(
      children: [
        // Outgoing page
        ScaleTransition(
          scale: outgoingScale,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.6).animate(
              CurvedAnimation(
                  parent: secondaryAnimation, curve: AppAnimations.decelerate),
            ),
            child: const _BlurOverlay(),
          ),
        ),
        // Incoming page
        ScaleTransition(
          scale: incomingScale,
          child: FadeTransition(
            opacity: incomingFade,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Slide-up + spring transition — used for bottom sheets and modals
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  SlideUpPageRoute({required this.page, super.settings})
      : super(
          transitionDuration: AppAnimations.expressive,
          reverseTransitionDuration: AppAnimations.standard,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: _buildTransitions,
          opaque: false,
          barrierColor: Colors.black54,
          barrierDismissible: true,
        );

  final Widget page;

  static Widget _buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: animation, curve: AppAnimations.expressiveEntrance));

    return SlideTransition(position: slide, child: child);
  }
}

/// Wallpaper Zoom transition — background zooms out while new page fades in
class WallpaperZoomPageRoute<T> extends PageRouteBuilder<T> {
  WallpaperZoomPageRoute({required this.page, super.settings})
      : super(
          transitionDuration: AppAnimations.slow,
          reverseTransitionDuration: AppAnimations.standard,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: _buildTransitions,
        );

  final Widget page;

  static Widget _buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut));

    final outScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic),
    );

    return Stack(
      children: [
        ScaleTransition(scale: outScale, child: const SizedBox.expand()),
        FadeTransition(opacity: fade, child: child),
      ],
    );
  }
}

/// Blur overlay widget used during transitions
class _BlurOverlay extends StatelessWidget {
  const _BlurOverlay();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: const SizedBox.expand(),
    );
  }
}

/// ─── Predictive Back Support ─────────────────────────────────────────────────
/// Wraps child with predictive back page transition theme.
/// Add this to your MaterialApp's pageTransitionsTheme.
const PageTransitionsTheme appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(
      allowEnterRouteSnapshotting: false,
    ),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
  },
);
