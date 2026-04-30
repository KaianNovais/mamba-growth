/// Pure date and aggregation helpers for the Home overview.
///
/// All functions are deterministic — no `DateTime.now()`, no I/O —
/// so they can be unit-tested without `pumpWidget` or fakes.
library;

import '../../../domain/models/meal.dart';

/// Strips the time-of-day from [d], returning midnight (00:00) of the same calendar day.
DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Sunday-anchored start of week (BR convention: dom = 0).
DateTime startOfWeekSunday(DateTime d) {
  final start = startOfDay(d);
  final daysFromSunday = start.weekday % 7; // Mon=1..Sun=7 → Mon=1..Sun=0
  return start.subtract(Duration(days: daysFromSunday));
}

/// Seven `DateTime`s at 00:00, dom→sáb, of the week containing [d].
List<DateTime> currentWeekDays(DateTime d) {
  final start = startOfWeekSunday(d);
  return List.generate(7, (i) => start.add(Duration(days: i)));
}

enum MealStatus { noGoal, underGoal, atGoal, overGoal }

class DayKcal {
  const DayKcal({required this.day, required this.kcal});
  final DateTime day;
  final int kcal;

  @override
  bool operator ==(Object other) =>
      other is DayKcal && other.day == day && other.kcal == kcal;

  @override
  int get hashCode => Object.hash(day, kcal);
}

/// Sums calories per day across the 7 days of the week starting at
/// [weekStart] (Sunday, 00:00). Meals outside the window are dropped.
List<DayKcal> aggregateWeekKcal({
  required List<Meal> meals,
  required DateTime weekStart,
}) {
  final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
  final totals = <DateTime, int>{for (final d in days) d: 0};
  for (final m in meals) {
    final day = startOfDay(m.eatenAt);
    if (totals.containsKey(day)) {
      totals[day] = totals[day]! + m.calories;
    }
  }
  return [for (final d in days) DayKcal(day: d, kcal: totals[d]!)];
}

/// Counts how many *closed* days (strictly before [today]) had `kcal <= goal`.
/// Returns `(0, 0)` when [goal] is null.
({int onTarget, int closed}) daysOnTarget({
  required List<DayKcal> weekDays,
  required int? goal,
  required DateTime today,
}) {
  if (goal == null) return (onTarget: 0, closed: 0);
  final todayStart = startOfDay(today);
  var onTarget = 0;
  var closed = 0;
  for (final d in weekDays) {
    if (!d.day.isBefore(todayStart)) continue;
    closed++;
    if (d.kcal <= goal) onTarget++;
  }
  return (onTarget: onTarget, closed: closed);
}

MealStatus computeStatus({required int consumed, required int? goal}) {
  if (goal == null || goal <= 0) return MealStatus.noGoal;
  if (consumed > goal) return MealStatus.overGoal;
  if (consumed == goal) return MealStatus.atGoal;
  return MealStatus.underGoal;
}
