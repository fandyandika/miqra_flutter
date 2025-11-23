import 'package:flutter/material.dart';

/// Animation utilities and helpers for consistent, subtle animations throughout the app
/// Inspired by Apple's Human Interface Guidelines for smooth, purposeful motion
class MiqraAnimations {
  // Duration constants (Apple HIG standards)
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);

  // Curves (Apple-inspired easing)
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.easeOutCubic;

  /// Subtle fade in animation for list items and cards
  ///
  /// Example:
  /// ```dart
  /// MiqraAnimations.fadeIn(
  ///   delay: index * 50,
  ///   child: MiqraCard(...),
  /// )
  /// ```
  static Widget fadeIn({
    required Widget child,
    int delay = 0,
    Duration duration = normal,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Subtle scale + fade animation for cards and important elements
  /// Creates a "pop in" effect
  ///
  /// Example:
  /// ```dart
  /// MiqraAnimations.scaleIn(
  ///   delay: 100,
  ///   child: MiqraCard(...),
  /// )
  /// ```
  static Widget scaleIn({
    required Widget child,
    int delay = 0,
    Duration duration = normal,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: spring,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (value * 0.05), // Scale from 0.95 to 1.0 (subtle)
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Slide in from bottom animation for bottom sheets and modals
  ///
  /// Example:
  /// ```dart
  /// MiqraAnimations.slideUp(
  ///   child: BottomSheetContent(),
  /// )
  /// ```
  static Widget slideUp({
    required Widget child,
    int delay = 0,
    Duration duration = normal,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)), // Slide from 20px below
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Staggered list animation helper
  /// Automatically animates each item with a delay based on index
  ///
  /// Example:
  /// ```dart
  /// ListView.builder(
  ///   itemBuilder: (context, index) {
  ///     return MiqraAnimations.staggeredItem(
  ///       index: index,
  ///       child: MiqraCard(...),
  ///     );
  ///   },
  /// )
  /// ```
  static Widget staggeredItem({
    required int index,
    required Widget child,
    int staggerDelay = 50, // ms between each item
    Duration duration = normal,
  }) {
    return fadeIn(
      delay: index * staggerDelay,
      duration: duration,
      child: child,
    );
  }
}

/// Custom page transition for consistent navigation animations
/// Usage with go_router:
/// ```dart
/// GoRoute(
///   path: '/surah/:id',
///   pageBuilder: (context, state) => MiqraPageTransition(
///     child: SurahDetailScreen(...),
///   ),
/// )
/// ```
class MiqraPageTransition extends CustomTransitionPage {
  MiqraPageTransition({
    required Widget child,
    LocalKey? key,
  }) : super(
          key: key,
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade + slight slide transition (Apple-style)
            const begin = Offset(0.03, 0.0); // Subtle 3% slide from right
            const end = Offset.zero;
            const curve = Curves.easeOut;

            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: MiqraAnimations.normal,
        );
}
