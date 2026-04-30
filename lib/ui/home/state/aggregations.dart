/// Pure date and aggregation helpers for the Home overview.
///
/// All functions are deterministic — no `DateTime.now()`, no I/O —
/// so they can be unit-tested without `pumpWidget` or fakes.
library;

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
