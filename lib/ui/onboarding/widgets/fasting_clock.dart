import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/themes/themes.dart';

class FastingClock extends StatelessWidget {
  const FastingClock({
    super.key,
    required this.fastingProgress,
    required this.calorieProgress,
    required this.timeLabel,
    required this.caption,
    this.size = 220,
  });

  final double fastingProgress;
  final double calorieProgress;
  final String timeLabel;
  final String caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _FastingClockPainter(
              fastingProgress: fastingProgress.clamp(0.0, 1.0),
              calorieProgress: calorieProgress.clamp(0.0, 1.0),
              fastingColor: colors.accent,
              calorieColor: colors.accent.withValues(alpha: 0.55),
              trackColor: colors.border.withValues(alpha: 0.55),
              glowColor: colors.accent.withValues(alpha: 0.35),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                caption,
                style: typo.caption.copyWith(
                  color: colors.accent,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timeLabel,
                style: typo.numericLarge.copyWith(
                  color: colors.text,
                  fontSize: 40,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FastingClockPainter extends CustomPainter {
  _FastingClockPainter({
    required this.fastingProgress,
    required this.calorieProgress,
    required this.fastingColor,
    required this.calorieColor,
    required this.trackColor,
    required this.glowColor,
  });

  final double fastingProgress;
  final double calorieProgress;
  final Color fastingColor;
  final Color calorieColor;
  final Color trackColor;
  final Color glowColor;

  static const _outerStroke = 7.0;
  static const _innerStroke = 4.0;
  static const _ringGap = 14.0;
  static const _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - _outerStroke;
    final innerRadius = outerRadius - _ringGap - (_outerStroke + _innerStroke) / 2;

    _paintRing(
      canvas: canvas,
      center: center,
      radius: outerRadius,
      strokeWidth: _outerStroke,
      progress: fastingProgress,
      activeColor: fastingColor,
      trackColor: trackColor,
      glowColor: glowColor,
    );

    _paintRing(
      canvas: canvas,
      center: center,
      radius: innerRadius,
      strokeWidth: _innerStroke,
      progress: calorieProgress,
      activeColor: calorieColor,
      trackColor: trackColor,
      glowColor: null,
    );
  }

  void _paintRing({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double strokeWidth,
    required double progress,
    required Color activeColor,
    required Color trackColor,
    required Color? glowColor,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweep = progress * 2 * math.pi;

    if (glowColor != null) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(rect, _startAngle, sweep, false, glowPaint);
    }

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = activeColor;
    canvas.drawArc(rect, _startAngle, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _FastingClockPainter old) {
    return old.fastingProgress != fastingProgress ||
        old.calorieProgress != calorieProgress ||
        old.fastingColor != fastingColor ||
        old.calorieColor != calorieColor ||
        old.trackColor != trackColor ||
        old.glowColor != glowColor;
  }
}
