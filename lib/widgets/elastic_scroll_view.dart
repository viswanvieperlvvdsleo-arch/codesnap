import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../utils/app_animations.dart';
import '../providers/theme_provider.dart';

/// ─── BouncingScrollBehavior ───────────────────────────────────────────────────
/// Global scroll behavior: bouncing on all platforms, no glow overscroll indicator.
class BouncingScrollBehavior extends ScrollBehavior {
  const BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child; // Remove default blue glow
}

/// ─── ElasticScrollView ───────────────────────────────────────────────────────
/// A CustomScrollView wrapper with:
/// - Bouncing physics on all platforms
/// - Pull-to-refresh with gold spinner
/// - Spring overscroll feel
class ElasticScrollView extends StatefulWidget {
  const ElasticScrollView({
    super.key,
    required this.slivers,
    this.onRefresh,
    this.controller,
  });

  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;

  @override
  State<ElasticScrollView> createState() => _ElasticScrollViewState();
}

class _ElasticScrollViewState extends State<ElasticScrollView>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      controller: widget.controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: widget.slivers,
    );

    if (widget.onRefresh == null) {
      return ScrollConfiguration(
        behavior: const BouncingScrollBehavior(),
        child: scrollView,
      );
    }

    return ScrollConfiguration(
      behavior: const BouncingScrollBehavior(),
      child: RefreshIndicator(
        onRefresh: widget.onRefresh!,
        color: ThemeProvider.primaryGold,
        backgroundColor: ThemeProvider.backgroundWarmWhite,
        displacement: 56,
        strokeWidth: 2.5,
        child: scrollView,
      ),
    );
  }
}
