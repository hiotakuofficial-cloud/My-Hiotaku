import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class BufferingLoader extends StatefulWidget {
  final bool isVisible;
  final double radius;
  final double strokeWidth;
  final int numberOfSegments;
  final Color primaryColor;
  final Color glowColor;
  final double glowSigma;

  const BufferingLoader({
    super.key,
    required this.isVisible,
    this.radius = 28.0,
    this.strokeWidth = 3.0,
    this.numberOfSegments = 8,
    this.primaryColor = const Color(0xFFE5003C),
    this.glowColor = const Color(0xFFFF4D4D),
    this.glowSigma = 5.0,
  });

  @override
  State<BufferingLoader> createState() => _BufferingLoaderState();
}

class _BufferingLoaderState extends State<BufferingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseScaleAnimation;
  late Animation<double> _breathingOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _pulseScaleAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.05),
        weight: 0.5,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 0.5,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _breathingOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        weight: 0.5,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 0.5,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _pulseScaleAnimation.value,
              child: Opacity(
                opacity: _breathingOpacityAnimation.value,
                child: CustomPaint(
                  size: Size.fromRadius(widget.radius + widget.glowSigma),
                  painter: BufferingPainter(
                    progress: _rotationAnimation.value,
                    radius: widget.radius,
                    strokeWidth: widget.strokeWidth,
                    numberOfSegments: widget.numberOfSegments,
                    primaryColor: widget.primaryColor,
                    glowColor: widget.glowColor,
                    glowSigma: widget.glowSigma,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BufferingPainter extends CustomPainter {
  final double progress;
  final double radius;
  final double strokeWidth;
  final int numberOfSegments;
  final Color primaryColor;
  final Color glowColor;
  final double glowSigma;

  BufferingPainter({
    required this.progress,
    required this.radius,
    required this.strokeWidth,
    required this.numberOfSegments,
    required this.primaryColor,
    required this.glowColor,
    required this.glowSigma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final segmentAngle = (2 * pi) / numberOfSegments;
    const gapAngle = 0.1;

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + (glowSigma * 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowSigma)
      ..strokeCap = StrokeCap.round;

    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < numberOfSegments; i++) {
      final startAngle = (i * segmentAngle) + (pi / 2);
      final sweepAngle = segmentAngle - gapAngle;

      final wavePhase = progress;
      final segmentCenterAngle = (i * segmentAngle) + (segmentAngle / 2);
      final normalizedProgress = (wavePhase - segmentCenterAngle + pi) % (2 * pi) - pi;
      double intensity = cos(normalizedProgress * 2.5);
      intensity = (intensity + 1) / 2;
      intensity = pow(intensity, 2).toDouble();
      intensity = intensity.clamp(0.0, 1.0);

      final currentGlowColor = glowColor.withOpacity(glowColor.opacity * intensity * 0.7);
      final currentPrimaryColor = primaryColor.withOpacity(primaryColor.opacity * intensity);

      if (intensity > 0.01) {
        glowPaint.color = currentGlowColor;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          glowPaint,
        );
      }

      strokePaint.color = currentPrimaryColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BufferingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.numberOfSegments != numberOfSegments ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.glowSigma != glowSigma;
  }
}
