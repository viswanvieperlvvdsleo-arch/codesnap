import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';

/// ─── CodeSnap Animation Design Tokens ───────────────────────────────────────
/// Central place for all animation constants — curves, durations, springs.
/// Every animated widget in the app pulls from here for consistency.
class AppAnimations {
  AppAnimations._();

  // ── Durations ────────────────────────────────────────────────────────────
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration expressive = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration verySlow = Duration(milliseconds: 900);

  // ── Cubic Bezier Curves ──────────────────────────────────────────────────
  /// Standard ease — smooth and natural
  static const Curve standard_ = Curves.easeInOutCubic;

  /// Overshoot — spring-like bounce past target then settle
  static const Curve overshoot = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Snappy — fast out, gentle settle
  static const Curve snappy = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Decelerate — starts fast, slows into position
  static const Curve decelerate = Curves.easeOutCubic;

  /// Accelerate — starts slow, exits fast
  static const Curve accelerate = Curves.easeInCubic;

  /// Expressive entrance — big overshoot for cards/modals
  static const Curve expressiveEntrance = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Bounce — elastic snap back
  static const Curve bounce = Curves.elasticOut;

  // ── Spring Descriptions ──────────────────────────────────────────────────

  /// Standard spring — balanced feel for most interactions
  static SpringDescription get standardSpring => const SpringDescription(
        mass: 1.0,
        stiffness: 400.0,
        damping: 28.0,
      );

  /// Snappy spring — fast settle, minimal oscillation
  static SpringDescription get snappySpring => const SpringDescription(
        mass: 0.8,
        stiffness: 600.0,
        damping: 38.0,
      );

  /// Bouncy spring — more oscillation, fun & playful
  static SpringDescription get bouncySpring => const SpringDescription(
        mass: 1.0,
        stiffness: 280.0,
        damping: 18.0,
      );

  /// Gentle spring — soft, luxury feel
  static SpringDescription get gentleSpring => const SpringDescription(
        mass: 1.2,
        stiffness: 200.0,
        damping: 22.0,
      );

  /// Heavy spring — for large elements (page transitions, drawers)
  static SpringDescription get heavySpring => const SpringDescription(
        mass: 2.0,
        stiffness: 300.0,
        damping: 35.0,
      );

  // ── Scale Values ─────────────────────────────────────────────────────────
  static const double pressScale = 0.94;
  static const double overshootScale = 1.04;
  static const double subtlePress = 0.97;

  // ── Stagger Delays ───────────────────────────────────────────────────────
  static Duration stagger(int index, {int baseMs = 60}) =>
      Duration(milliseconds: baseMs * index);

  // ── Spring Simulation Helper ─────────────────────────────────────────────
  static SpringSimulation springSimulation(
    SpringDescription description, {
    double from = 0.0,
    double to = 1.0,
    double velocity = 0.0,
  }) =>
      SpringSimulation(description, from, to, velocity);
}
