import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../themes/themes.dart';

/// Linha de 7 círculos representando a semana atual (domingo→sábado, padrão BR).
///
/// Hoje fica destacado mesmo quando não selecionado. Dias futuros ficam
/// visíveis mas desabilitados. Toque dispara haptic + [onSelect].
class WeekDaySelector extends StatelessWidget {
  const WeekDaySelector({
    super.key,
    required this.weekDays,
    required this.today,
    required this.selectedDay,
    required this.onSelect,
  });

  final List<DateTime> weekDays;
  final DateTime today;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelect;

  /// Início da semana com domingo = dia 0 (padrão BR), normalizado a 00:00.
  static DateTime startOfWeekSunday(DateTime d) {
    final daysFromSunday = d.weekday % 7; // dom=0, seg=1, ..., sáb=6
    return DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: daysFromSunday));
  }

  /// Lista com os 7 dias (00:00) da semana de [d], em ordem dom→sáb.
  static List<DateTime> currentWeekDays(DateTime d) {
    final start = startOfWeekSunday(d);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  void _handleTap(DateTime day) {
    if (day.isAtSameMomentAs(selectedDay)) return;
    HapticFeedback.selectionClick();
    onSelect(day);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in weekDays)
          _DayCircle(
            day: day,
            isToday: day.isAtSameMomentAs(today),
            isSelected: day.isAtSameMomentAs(selectedDay),
            isFuture: day.isAfter(today),
            onTap: day.isAfter(today) ? null : () => _handleTap(day),
          ),
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final VoidCallback? onTap;

  static const _diameter = 40.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final letter = DateFormat.EEEEE(locale).format(day).toUpperCase();
    final dayNum = day.day.toString();

    final Color bg;
    final Color fg;
    final Color borderColor;
    if (isSelected) {
      bg = colors.accent;
      fg = colors.bg;
      borderColor = colors.accent;
    } else if (isToday) {
      bg = Colors.transparent;
      fg = colors.accent;
      borderColor = colors.accent;
    } else if (isFuture) {
      bg = Colors.transparent;
      fg = colors.textDimmer;
      borderColor = colors.borderDim;
    } else {
      bg = Colors.transparent;
      fg = colors.text;
      borderColor = colors.border;
    }

    final letterColor = isFuture ? colors.textDimmer : colors.textDim;
    final state = isFuture
        ? 'future'
        : isSelected
            ? 'selected'
            : isToday
                ? 'today'
                : 'past';

    return Semantics(
      button: !isFuture,
      enabled: !isFuture,
      label: l10n.weekSelectorDayA11y(
        DateFormat.EEEE(locale).format(day),
        day.day,
        state,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            letter,
            style: typo.caption.copyWith(
              color: letterColor,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // InkResponse envolve só o círculo: splash respeita o raio
          // do dia (não invade a letra acima) e fica centrado no
          // próprio círculo em vez do centro da Column.
          InkResponse(
            onTap: onTap,
            radius: _diameter / 2,
            customBorder: const CircleBorder(),
            child: Container(
              width: _diameter,
              height: _diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: Border.all(
                  color: borderColor,
                  width: isSelected || isToday ? 1.5 : 1,
                ),
              ),
              child: Text(
                dayNum,
                style: text.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
