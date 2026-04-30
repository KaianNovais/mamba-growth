import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import 'week_kcal_chart_painter.dart';

export 'week_kcal_chart_painter.dart' show WeekKcalChartData;

class WeekKcalChart extends StatelessWidget {
  const WeekKcalChart({
    super.key,
    required this.data,
    required this.onSelectDay,
  });

  final WeekKcalChartData data;
  final ValueChanged<int> onSelectDay;

  static const double _height = 180;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    final selected = data.days[data.selectedIndex];
    final selectedDayLabel = _weekdayName(data.selectedIndex, l10n);

    return Semantics(
      label: l10n.homeChartA11y(
        // Counts derived from data alone are not enough; we need the closed
        // counts. The Home screen wraps WeekKcalChart with a Selector that
        // already passes the right data — but a11y stays useful with a
        // minimal label here.
        0,
        0,
        selectedDayLabel,
        selected.kcal,
      ),
      child: SizedBox(
        height: _height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final width = (context.findRenderObject() as RenderBox).size.width;
            final innerWidth = width - 32; // _leftPad + _rightPad
            final colWidth = innerWidth / 7;
            final i = ((details.localPosition.dx - 16) / colWidth).floor();
            if (i < 0 || i > 6) return;
            if (i >= data.firstFutureIndex) return;
            onSelectDay(i);
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: WeekKcalChartPainter(
              data: data,
              surfaceColor: colors.surface,
              barNeutralColor: colors.surface2,
              accent: colors.accent,
              accentWarm: colors.accentWarm,
              borderDim: colors.borderDim,
              text: colors.text,
              textDim: colors.textDim,
              textDimmer: colors.textDimmer,
              weekdayLetters: l10n.homeWeekdayLetters,
              goalLabel: data.goal == null
                  ? ''
                  : l10n.homeWeekChartGoalLabel(data.goal!),
              selectedKcalLabel: data.selectedIndex < data.firstFutureIndex
                  ? selected.kcal.toString()
                  : null,
              barAnimation: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

String _weekdayName(int index, AppLocalizations l10n) {
  return l10n.homeWeekdayLetters.substring(index, index + 1);
}
