import 'package:flutter/material.dart';

import '../state/aggregations.dart';

class WeekKcalChartData {
  const WeekKcalChartData({
    required this.days,
    required this.goal,
    required this.todayIndex,
    required this.selectedIndex,
    required this.firstFutureIndex,
  });

  final List<DayKcal> days;
  final int? goal;
  final int todayIndex;
  final int selectedIndex;
  final int firstFutureIndex;
}

class WeekKcalChartPainter extends CustomPainter {
  WeekKcalChartPainter({
    required this.data,
    required this.surfaceColor,
    required this.barNeutralColor,
    required this.accent,
    required this.accentWarm,
    required this.borderDim,
    required this.text,
    required this.textDim,
    required this.textDimmer,
    required this.weekdayLetters,
    required this.goalLabel,
    required this.selectedKcalLabel,
    required this.barAnimation,
  });

  final WeekKcalChartData data;
  final Color surfaceColor;
  final Color barNeutralColor;
  final Color accent;
  final Color accentWarm;
  final Color borderDim;
  final Color text;
  final Color textDim;
  final Color textDimmer;
  final String weekdayLetters; // 7 chars, dom→sáb
  final String goalLabel;       // e.g. "meta 2000"
  final String? selectedKcalLabel; // e.g. "1840"
  final double barAnimation; // 0..1; multiplies bar heights for entry anim

  static const _leftPad = 16.0;
  static const _rightPad = 16.0;
  static const _topPad = 32.0;
  static const _bottomPad = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final innerWidth = size.width - _leftPad - _rightPad;
    final innerHeight = size.height - _topPad - _bottomPad;
    final colWidth = innerWidth / 7;
    final maxKcal = data.days
        .map((d) => d.kcal)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final scaleMax = ([
      maxKcal,
      data.goal ?? 0,
    ].fold<int>(0, (a, b) => a > b ? a : b)) *
        1.15;
    final yScale = scaleMax <= 0 ? 0.0 : innerHeight / scaleMax;

    // 1. Goal line + label
    if (data.goal != null) {
      final y = size.height - _bottomPad - data.goal! * yScale;
      _paintDashedLine(
        canvas,
        Offset(_leftPad, y),
        Offset(size.width - _rightPad, y),
        color: borderDim,
        dash: 4,
        gap: 4,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: goalLabel,
          style: TextStyle(color: textDim, fontSize: 11, fontFamily: 'GeistMono'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - _rightPad - tp.width, y - tp.height - 2));
    }

    // 2. Bars or future dots
    final baseY = size.height - _bottomPad;
    for (var i = 0; i < 7; i++) {
      final cx = _leftPad + colWidth * (i + 0.5);
      if (i >= data.firstFutureIndex) {
        // Future dot
        canvas.drawCircle(
          Offset(cx, baseY - 2),
          2,
          Paint()..color = borderDim,
        );
        continue;
      }
      final kcal = data.days[i].kcal;
      final isSelected = i == data.selectedIndex;
      final isOver = data.goal != null && kcal > data.goal!;
      final barColor = isSelected
          ? (isOver ? accentWarm : accent)
          : barNeutralColor;
      final fullHeight = kcal * yScale;
      final h = fullHeight * barAnimation;
      final barWidth = colWidth * 0.55;
      final left = cx - barWidth / 2;

      if (kcal == 0 && i == data.todayIndex) {
        // Ghost line for today with no data.
        canvas.drawRect(
          Rect.fromLTWH(left, baseY - 1, barWidth, 1),
          Paint()..color = borderDim,
        );
        continue;
      }

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, baseY - h, barWidth, h),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rrect, Paint()..color = barColor);
    }

    // 3. Selected label above the selected bar
    final selLabel = selectedKcalLabel;
    final canShowLabel =
        selLabel != null && data.selectedIndex < data.firstFutureIndex;
    if (canShowLabel) {
      final i = data.selectedIndex;
      final cx = _leftPad + colWidth * (i + 0.5);
      final kcal = data.days[i].kcal;
      final fullHeight = kcal * yScale;
      final h = fullHeight * barAnimation;
      final tp = TextPainter(
        text: TextSpan(
          text: selLabel,
          style: TextStyle(
            color: text,
            fontSize: 18,
            height: 1.2,
            fontFamily: 'GeistMono',
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, baseY - h - tp.height - 6));
    }

    // 4. Axis line
    canvas.drawLine(
      Offset(_leftPad, baseY),
      Offset(size.width - _rightPad, baseY),
      Paint()
        ..color = borderDim
        ..strokeWidth = 1,
    );

    // 5. Weekday letters
    for (var i = 0; i < 7; i++) {
      final cx = _leftPad + colWidth * (i + 0.5);
      final letter = weekdayLetters.substring(i, i + 1);
      final isToday = i == data.todayIndex;
      final tp = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: isToday ? text : textDim,
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, size.height - _bottomPad + 8),
      );
    }
  }

  void _paintDashedLine(
    Canvas canvas,
    Offset a,
    Offset b, {
    required Color color,
    required double dash,
    required double gap,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final total = (b - a).distance;
    final dx = (b.dx - a.dx) / total;
    final dy = (b.dy - a.dy) / total;
    var traveled = 0.0;
    var drawing = true;
    while (traveled < total) {
      final segLength = drawing ? dash : gap;
      final seg = (traveled + segLength).clamp(0.0, total);
      if (drawing) {
        canvas.drawLine(
          Offset(a.dx + dx * traveled, a.dy + dy * traveled),
          Offset(a.dx + dx * seg, a.dy + dy * seg),
          paint,
        );
      }
      traveled = seg;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(WeekKcalChartPainter old) =>
      old.data != data ||
      old.barAnimation != barAnimation ||
      old.selectedKcalLabel != selectedKcalLabel ||
      old.goalLabel != goalLabel;
}
