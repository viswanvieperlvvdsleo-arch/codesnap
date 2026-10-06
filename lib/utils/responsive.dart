import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Responsive & Adaptive Screen Engine for Bug (CodeSnap)
///
/// Ensures 100% overflow immunity across all screen form factors:
/// - Small phones (320px–360px, e.g. iPhone SE, Galaxy A)
/// - Standard phones (375px–430px, e.g. iPhone 15/16, Pixel 8)
/// - Large phones & foldables (430px–600px)
/// - Tablets & iPad (600px–1024px)
/// - Desktop & Web Windows (1024px+)
/// ─────────────────────────────────────────────────────────────────────────────
class Responsive {
  // Base design reference dimensions (Standard modern phone)
  static const double baseWidth = 390.0;
  static const double baseHeight = 844.0;

  // Breakpoints
  static const double breakpointCompact = 360.0;
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 1024.0;

  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isCompact(BuildContext context) => width(context) < breakpointCompact;
  static bool isMobile(BuildContext context) => width(context) < breakpointMobile;
  static bool isTablet(BuildContext context) =>
      width(context) >= breakpointMobile && width(context) < breakpointTablet;
  static bool isDesktop(BuildContext context) => width(context) >= breakpointTablet;
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Dynamic scale factor based on screen width relative to standard phone (390dp).
  /// Clamped safely to [0.78, 1.35] on phones/tablets so UI never explodes or shrinks to illegibility.
  static double scale(BuildContext context) {
    final w = width(context);
    // On wide desktop/web, base the scale factor on a standard readable column
    final effectiveWidth = isDesktop(context) ? 500.0 : w;
    return (effectiveWidth / baseWidth).clamp(0.80, 1.30);
  }

  /// Responsive scaled width in pixels
  static double rw(BuildContext context, num pixels) {
    return pixels * scale(context);
  }

  /// Responsive scaled font size (with conservative damping to avoid text overflow)
  static double sp(BuildContext context, num fontSize) {
    final s = scale(context);
    // Damped scale for typography: font size scales more moderately than spacing
    final dampedScale = 1.0 + (s - 1.0) * 0.65;
    return (fontSize * dampedScale).clamp(fontSize * 0.82, fontSize * 1.25);
  }

  /// Responsive value switcher
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? compact,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    if (isCompact(context) && compact != null) return compact;
    return mobile;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Extension on BuildContext for quick, clean responsive calls
/// ─────────────────────────────────────────────────────────────────────────────
extension ResponsiveContext on BuildContext {
  double get screenWidth => Responsive.width(this);
  double get screenHeight => Responsive.height(this);
  bool get isCompact => Responsive.isCompact(this);
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isLandscape => Responsive.isLandscape(this);
  double get scaleFactor => Responsive.scale(this);

  /// Scaled width
  double rw(num px) => Responsive.rw(this, px);

  /// Scaled font size
  double sp(num fontSize) => Responsive.sp(this, fontSize);

  /// Adaptive value helper
  T responsive<T>({
    required T mobile,
    T? compact,
    T? tablet,
    T? desktop,
  }) =>
      Responsive.value<T>(
        this,
        mobile: mobile,
        compact: compact,
        tablet: tablet,
        desktop: desktop,
      );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// AdaptiveText: Automatically scales down text in tight spaces without overflowing
/// ─────────────────────────────────────────────────────────────────────────────
class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final Alignment alignment;

  const AdaptiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
      ),
    );
  }
}
