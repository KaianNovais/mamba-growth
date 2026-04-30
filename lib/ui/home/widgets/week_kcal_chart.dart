import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import 'week_kcal_chart_painter.dart';

export 'week_kcal_chart_painter.dart' show WeekKcalChartData;

class WeekKcalChart extends StatefulWidget {
  const WeekKcalChart({
    super.key,
    required this.data,
    required this.onSelectDay,
  });

  final WeekKcalChartData data;
  final ValueChanged<int> onSelectDay;

  static const double _height = 180;

  @override
  State<WeekKcalChart> createState() => _WeekKcalChartState();
}

class _WeekKcalChartState extends State<WeekKcalChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0, // start full; we'll reset to 0 if motion is allowed
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduced) return;
      _ctrl
        ..value = 0
        ..forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final selected = widget.data.days[widget.data.selectedIndex];
    final selectedDayLabel = l10n.homeWeekdayLetters
        .substring(widget.data.selectedIndex, widget.data.selectedIndex + 1);

    return Semantics(
      label: l10n.homeChartA11y(
        0,
        0,
        selectedDayLabel,
        selected.kcal,
      ),
      child: SizedBox(
        height: WeekKcalChart._height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final width =
                (context.findRenderObject() as RenderBox).size.width;
            final innerWidth = width - 32;
            final colWidth = innerWidth / 7;
            final i = ((details.localPosition.dx - 16) / colWidth).floor();
            if (i < 0 || i > 6) return;
            if (i >= widget.data.firstFutureIndex) return;
            widget.onSelectDay(i);
          },
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: WeekKcalChartPainter(
                  data: widget.data,
                  surfaceColor: colors.surface,
                  barNeutralColor: colors.surface2,
                  accent: colors.accent,
                  accentWarm: colors.accentWarm,
                  borderDim: colors.borderDim,
                  text: colors.text,
                  textDim: colors.textDim,
                  textDimmer: colors.textDimmer,
                  weekdayLetters: l10n.homeWeekdayLetters,
                  goalLabel: widget.data.goal == null
                      ? ''
                      : l10n.homeWeekChartGoalLabel(widget.data.goal!),
                  selectedKcalLabel:
                      widget.data.selectedIndex < widget.data.firstFutureIndex
                          ? selected.kcal.toString()
                          : null,
                  barAnimation:
                      Curves.easeOutCubic.transform(_ctrl.value),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
