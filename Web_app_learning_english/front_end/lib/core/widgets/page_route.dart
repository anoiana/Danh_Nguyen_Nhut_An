import 'package:flutter/material.dart';

/// A custom page route that provides a scale and fade transition effect.
class ScaleFadePageRoute extends PageRouteBuilder {
  final Widget page;

  ScaleFadePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Define the scale animation: starts at 85% size and scales up to 100%
          final scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          // Define the fade animation: fades in from transparent to opaque
          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      );
}
