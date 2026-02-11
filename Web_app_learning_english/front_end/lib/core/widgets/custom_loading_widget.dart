import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomLoadingWidget extends StatefulWidget {
  final Color? color;
  final String? message;
  final double size;

  const CustomLoadingWidget({
    super.key,
    this.color,
    this.message,
    this.size = 80.0,
  });

  @override
  State<CustomLoadingWidget> createState() => _CustomLoadingWidgetState();
}

class _CustomLoadingWidgetState extends State<CustomLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? const Color(0xFFE91E63);
    final size = widget.size;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Rings
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      width: size * _animation.value,
                      height: size * _animation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(1 - _animation.value),
                          width: size * 0.05,
                        ),
                      ),
                    );
                  },
                ),
                // Inner pulsing circle
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale:
                          0.8 +
                          (0.2 * math.sin(_controller.value * 2 * math.pi)),
                      child: Container(
                        width: size * 0.5,
                        height: size * 0.5,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: size * 0.15,
                              spreadRadius: size * 0.025,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.hourglass_empty_rounded,
                          color: Colors.white,
                          size: size * 0.25,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
