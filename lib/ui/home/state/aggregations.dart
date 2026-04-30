/// Pure date and aggregation helpers for the Home overview.
///
/// All functions are deterministic — no `DateTime.now()`, no I/O —
/// so they can be unit-tested without `pumpWidget` or fakes.
library;

import '../../../domain/models/fast.dart';
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

/// Returns [MealStatus.noGoal] when [goal] is null or ≤ 0; otherwise
/// compares [consumed] against [goal] for over/at/under status.
MealStatus computeStatus({required int consumed, required int? goal}) {
  if (goal == null || goal <= 0) return MealStatus.noGoal;
  if (consumed > goal) return MealStatus.overGoal;
  if (consumed == goal) return MealStatus.atGoal;
  return MealStatus.underGoal;
}

class WeeklyFastingSummary {
  const WeeklyFastingSummary({
    required this.completed,
    required this.total,
    required this.totalDuration,
    required this.average,
  });

  final int completed;
  final int total;
  final Duration totalDuration;
  final Duration average;

  static const empty = WeeklyFastingSummary(
    completed: 0,
    total: 0,
    totalDuration: Duration.zero,
    average: Duration.zero,
  );
}

/// Aggregates fasts whose `endAt` falls in `[weekStart, weekStart + 7d)`.
/// `average` is `totalDuration` divided by the number of distinct days
/// with at least one fast (NOT by 7 — empty days do not pull the average down).
WeeklyFastingSummary aggregateWeeklyFasting({
  required List<Fast> fasts,
  required DateTime weekStart,
}) {
  final weekEnd = weekStart.add(const Duration(days: 7));
  final inWeek = <Fast>[];
  for (final f in fasts) {
    final end = f.endAt;
    if (end == null) continue;
    if (end.isBefore(weekStart) || !end.isBefore(weekEnd)) continue;
    inWeek.add(f);
  }
  if (inWeek.isEmpty) return WeeklyFastingSummary.empty;

  var completed = 0;
  var totalMicros = 0;
  final daysWithFasts = <DateTime>{};
  for (final f in inWeek) {
    if (f.completed) completed++;
    totalMicros += f.endAt!.difference(f.startAt).inMicroseconds;
    daysWithFasts.add(startOfDay(f.endAt!));
  }
  final total = inWeek.length;
  final totalDuration = Duration(microseconds: totalMicros);
  final average = Duration(microseconds: totalMicros ~/ daysWithFasts.length);
  return WeeklyFastingSummary(
    completed: completed,
    total: total,
    totalDuration: totalDuration,
    average: average,
  );
}

/// Returns the fast with the most recent non-null `endAt`, or null.
Fast? lastFinishedFast(List<Fast> fasts) {
  Fast? best;
  for (final f in fasts) {
    final end = f.endAt;
    if (end == null) continue;
    if (best == null || end.isAfter(best.endAt!)) best = f;
  }
  return best;
}
