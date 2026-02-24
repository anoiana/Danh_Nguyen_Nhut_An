import 'dart:math';
import 'package:flutter/material.dart';

void showGameFinishDialog({
  required BuildContext context,
  required int correctCount,
  required int wrongCount,
  required VoidCallback onClose,
  required VoidCallback onReplay,
  int wrongWordsCount = 0,
  VoidCallback? onRetryWrongWords,
  Map<String, String>? extraStats,
  String? subtitle,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'GameFinish',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, anim1, anim2) {
      return _GameFinishDialog(
        correctCount: correctCount,
        wrongCount: wrongCount,
        onClose: onClose,
        onReplay: onReplay,
        wrongWordsCount: wrongWordsCount,
        onRetryWrongWords: onRetryWrongWords,
        extraStats: extraStats,
        subtitle: subtitle,
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      final curvedAnim = CurvedAnimation(
        parent: anim1,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curvedAnim),
          child: child,
        ),
      );
    },
  );
}

class _GameFinishDialog extends StatefulWidget {
  final int correctCount;
  final int wrongCount;
  final VoidCallback onClose;
  final VoidCallback onReplay;
  final int wrongWordsCount;
  final VoidCallback? onRetryWrongWords;
  final Map<String, String>? extraStats;
  final String? subtitle;

  const _GameFinishDialog({
    super.key,
    required this.correctCount,
    required this.wrongCount,
    required this.onClose,
    required this.onReplay,
    required this.wrongWordsCount,
    this.onRetryWrongWords,
    this.extraStats,
    this.subtitle,
  });

  @override
  State<_GameFinishDialog> createState() => _GameFinishDialogState();
}

class _GameFinishDialogState extends State<_GameFinishDialog>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _staggerController;

  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    final double total = (widget.correctCount + widget.wrongCount).toDouble();
    final double percentage = total > 0 ? widget.correctCount / total : 0;

    // Progress ring animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(begin: 0, end: percentage).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    // Pulse animation for the icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Stagger animation for content
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double total = (widget.correctCount + widget.wrongCount).toDouble();
    final double percentage = total > 0 ? widget.correctCount / total : 0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    String title;
    String message;
    List<Color> gradientColors;
    IconData headerIcon;

    if (percentage >= 0.8) {
      title = 'Tuyệt vời! 🎉';
      message = widget.subtitle ?? 'Bạn đã làm rất tốt!';
      gradientColors = [const Color(0xFF43E97B), const Color(0xFF38F9D7)];
      headerIcon = Icons.emoji_events_rounded;
    } else if (percentage >= 0.5) {
      title = 'Hoàn thành!';
      message = widget.subtitle ?? 'Cố gắng hơn nữa nhé!';
      gradientColors = [const Color(0xFFFA8BFF), const Color(0xFF2BD2FF)];
      headerIcon = Icons.thumb_up_alt_rounded;
    } else {
      title = 'Kết thúc';
      message = widget.subtitle ?? 'Đừng nản lòng, hãy thử lại!';
      gradientColors = [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];
      headerIcon = Icons.sentiment_dissatisfied_rounded;
    }

    final Color cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final Color surfaceBg =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Main Card ──
          Container(
            margin: const EdgeInsets.only(top: 48),
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Title ──
                _buildStaggerChild(
                  index: 0,
                  child: ShaderMask(
                    shaderCallback:
                        (bounds) => LinearGradient(
                          colors: gradientColors,
                        ).createShader(bounds),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _buildStaggerChild(
                  index: 1,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Score Ring ──
                _buildStaggerChild(
                  index: 2,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        width: 110,
                        height: 110,
                        child: CustomPaint(
                          painter: _ScoreRingPainter(
                            progress: _progressAnimation.value,
                            gradientColors: gradientColors,
                            trackColor:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.grey.shade200,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(_progressAnimation.value * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : Colors.grey.shade800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Điểm số',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.4,
                                            )
                                            : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Stats Row ──
                _buildStaggerChild(
                  index: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            label: 'Đúng',
                            count: widget.correctCount,
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF43E97B),
                            isDark: isDark,
                          ),
                        ),
                        Container(
                          height: 44,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.grey.shade300,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            label: 'Sai',
                            count: widget.wrongCount,
                            icon: Icons.cancel_rounded,
                            color: const Color(0xFFFF6B6B),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Extra Stats ──
                if (widget.extraStats != null &&
                    widget.extraStats!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildStaggerChild(
                    index: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children:
                            widget.extraStats!.entries
                                .map(
                                  (e) => Column(
                                    children: [
                                      Text(
                                        e.value,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.key,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              isDark
                                                  ? Colors.white.withValues(
                                                    alpha: 0.5,
                                                  )
                                                  : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Action Buttons ──
                _buildStaggerChild(
                  index: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Retry wrong words button
                      if (widget.onRetryWrongWords != null &&
                          widget.wrongWordsCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildGradientButton(
                            context,
                            onPressed: widget.onRetryWrongWords!,
                            icon: Icons.refresh_rounded,
                            label: 'Ôn lại ${widget.wrongWordsCount} từ sai',
                            colors: [
                              const Color(0xFFFF8E53),
                              const Color(0xFFFF6B6B),
                            ],
                          ),
                        ),

                      // Replay button
                      _buildGradientButton(
                        context,
                        onPressed: widget.onReplay,
                        icon: Icons.replay_rounded,
                        label: 'Chơi lại',
                        colors: gradientColors,
                      ),
                      const SizedBox(height: 12),

                      // Exit button
                      TextButton(
                        onPressed: widget.onClose,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Text(
                          'Thoát',
                          style: TextStyle(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.grey.shade500,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating Icon Badge ──
          Positioned(
            top: 0,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: gradientColors[1].withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: cardBg, width: 5),
                ),
                child: Icon(headerIcon, color: Colors.white, size: 36),
              ),
            ),
          ),

          // ── Decorative sparkle dots (for high scores) ──
          if (percentage >= 0.8) ...[
            Positioned(
              top: 10,
              left: 30,
              child: _SparkleWidget(color: gradientColors[0], delay: 0),
            ),
            Positioned(
              top: 20,
              right: 40,
              child: _SparkleWidget(color: gradientColors[1], delay: 300),
            ),
            Positioned(
              top: 60,
              left: 50,
              child: _SparkleWidget(
                color: gradientColors[0].withValues(alpha: 0.7),
                delay: 600,
              ),
            ),
            Positioned(
              top: 50,
              right: 60,
              child: _SparkleWidget(
                color: gradientColors[1].withValues(alpha: 0.7),
                delay: 150,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaggerChild({required int index, required Widget child}) {
    final begin = (index * 0.12).clamp(0.0, 0.8);
    final end = (begin + 0.4).clamp(0.0, 1.0);

    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradientButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom Painter for Score Ring ──
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final Color trackColor;

  _ScoreRingPainter({
    required this.progress,
    required this.gradientColors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Track
    final trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [gradientColors[0], gradientColors[1], gradientColors[0]],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-pi / 2),
      );

      final progressPaint =
          Paint()
            ..shader = gradient.createShader(rect)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);

      // End dot glow
      final endAngle = -pi / 2 + 2 * pi * progress;
      final dotCenter = Offset(
        center.dx + radius * cos(endAngle),
        center.dy + radius * sin(endAngle),
      );

      final glowPaint =
          Paint()
            ..color = gradientColors[1].withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(dotCenter, 6, glowPaint);

      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(dotCenter, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ── Sparkle Widget ──
class _SparkleWidget extends StatefulWidget {
  final Color color;
  final int delay;

  const _SparkleWidget({required this.color, required this.delay});

  @override
  State<_SparkleWidget> createState() => _SparkleWidgetState();
}

class _SparkleWidgetState extends State<_SparkleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1), weight: 30),
    ]).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
