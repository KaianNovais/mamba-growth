import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/domain/models/fast.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/ui/home/state/aggregations.dart';

void main() {
  group('startOfDay', () {
    test('strips time-of-day', () {
      final d = DateTime(2026, 4, 30, 13, 45, 12);
      expect(startOfDay(d), DateTime(2026, 4, 30));
    });
  });

  group('startOfWeekSunday', () {
    test('Sunday returns same Sunday at 00:00', () {
      final d = DateTime(2026, 4, 26, 22, 10); // Sunday
      expect(startOfWeekSunday(d), DateTime(2026, 4, 26));
    });

    test('Monday returns previous Sunday at 00:00', () {
      final d = DateTime(2026, 4, 27, 8); // Monday
      expect(startOfWeekSunday(d), DateTime(2026, 4, 26));
    });

    test('Wednesday returns previous Sunday at 00:00', () {
      final d = DateTime(2026, 4, 29, 9); // Wednesday
      expect(startOfWeekSunday(d), DateTime(2026, 4, 26));
    });

    test('Saturday returns Sunday 6 days back', () {
      final d = DateTime(2026, 5, 2, 23, 59); // Saturday
      expect(startOfWeekSunday(d), DateTime(2026, 4, 26));
    });
  });

  group('currentWeekDays', () {
    test('returns 7 sequential days dom→sáb at 00:00', () {
      final week = currentWeekDays(DateTime(2026, 4, 29));
      expect(week, [
        DateTime(2026, 4, 26),
        DateTime(2026, 4, 27),
        DateTime(2026, 4, 28),
        DateTime(2026, 4, 29),
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 2),
      ]);
    });
  });

  group('aggregateWeekKcal', () {
    final weekStart = DateTime(2026, 4, 26); // Sunday

    Meal meal({required int id, required DateTime when, required int kcal}) =>
        Meal(id: id, name: 'm$id', calories: kcal, eatenAt: when);

    test('returns 7 days with zero kcal when meals empty', () {
      final out = aggregateWeekKcal(meals: const [], weekStart: weekStart);
      expect(out.length, 7);
      expect(out.map((d) => d.kcal).toSet(), {0});
      expect(out.first.day, weekStart);
      expect(out.last.day, DateTime(2026, 5, 2));
    });

    test('sums calories per day', () {
      final out = aggregateWeekKcal(
        meals: [
          meal(id: 1, when: DateTime(2026, 4, 27, 8), kcal: 400),
          meal(id: 2, when: DateTime(2026, 4, 27, 19), kcal: 600),
          meal(id: 3, when: DateTime(2026, 4, 29, 12), kcal: 800),
        ],
        weekStart: weekStart,
      );
      expect(out[1].kcal, 1000); // Monday
      expect(out[3].kcal, 800); // Wednesday
      expect(out[0].kcal, 0);
    });

    test('meal at 23:59 belongs to its day; 00:01 next day to next', () {
      final out = aggregateWeekKcal(
        meals: [
          meal(id: 1, when: DateTime(2026, 4, 27, 23, 59), kcal: 100),
          meal(id: 2, when: DateTime(2026, 4, 28, 0, 1), kcal: 200),
        ],
        weekStart: weekStart,
      );
      expect(out[1].kcal, 100); // Monday
      expect(out[2].kcal, 200); // Tuesday
    });

    test('drops meals outside the week window', () {
      final out = aggregateWeekKcal(
        meals: [
          meal(id: 1, when: DateTime(2026, 4, 25, 12), kcal: 999),
          meal(id: 2, when: DateTime(2026, 5, 3, 12), kcal: 999),
        ],
        weekStart: weekStart,
      );
      expect(out.map((d) => d.kcal).toSet(), {0});
    });
  });

  group('daysOnTarget', () {
    final weekStart = DateTime(2026, 4, 26);
    final week = List.generate(
      7,
      (i) => DayKcal(day: weekStart.add(Duration(days: i)), kcal: 0),
    );

    test('returns 0/0 when goal is null', () {
      final r = daysOnTarget(
        weekDays: week,
        goal: null,
        today: DateTime(2026, 4, 30),
      );
      expect(r.onTarget, 0);
      expect(r.closed, 0);
    });

    test('counts only days strictly before today', () {
      final w = [
        DayKcal(day: DateTime(2026, 4, 26), kcal: 1500), // Sun (closed, on)
        DayKcal(day: DateTime(2026, 4, 27), kcal: 2100), // Mon (closed, over)
        DayKcal(day: DateTime(2026, 4, 28), kcal: 0), // Tue (closed, on - 0 counts)
        DayKcal(day: DateTime(2026, 4, 29), kcal: 1800), // Wed (closed, on)
        DayKcal(day: DateTime(2026, 4, 30), kcal: 1200), // Thu (today, NOT closed)
        DayKcal(day: DateTime(2026, 5, 1), kcal: 0), // Fri (future)
        DayKcal(day: DateTime(2026, 5, 2), kcal: 0), // Sat (future)
      ];
      final r = daysOnTarget(weekDays: w, goal: 2000, today: DateTime(2026, 4, 30));
      expect(r.closed, 4);
      expect(r.onTarget, 3);
    });

    test('Sunday 00:00 → no closed days', () {
      final r = daysOnTarget(
        weekDays: week,
        goal: 2000,
        today: DateTime(2026, 4, 26),
      );
      expect(r.closed, 0);
      expect(r.onTarget, 0);
    });
  });

  group('computeStatus', () {
    test('null goal → noGoal', () {
      expect(computeStatus(consumed: 1500, goal: null), MealStatus.noGoal);
    });
    test('zero goal → noGoal', () {
      expect(computeStatus(consumed: 1500, goal: 0), MealStatus.noGoal);
    });
    test('consumed < goal → underGoal', () {
      expect(computeStatus(consumed: 1500, goal: 2000), MealStatus.underGoal);
    });
    test('consumed == goal → atGoal', () {
      expect(computeStatus(consumed: 2000, goal: 2000), MealStatus.atGoal);
    });
    test('consumed == goal + 1 → overGoal', () {
      expect(computeStatus(consumed: 2001, goal: 2000), MealStatus.overGoal);
    });
  });

  group('aggregateWeeklyFasting', () {
    final weekStart = DateTime(2026, 4, 26);

    Fast f({
      required int id,
      required DateTime startAt,
      required DateTime? endAt,
      int targetHours = 16,
      bool completed = true,
    }) =>
        Fast(
          id: id,
          startAt: startAt,
          endAt: endAt,
          targetHours: targetHours,
          eatingHours: 8,
          completed: completed,
        );

    test('empty list → zeros', () {
      final s = aggregateWeeklyFasting(fasts: const [], weekStart: weekStart);
      expect(s.completed, 0);
      expect(s.total, 0);
      expect(s.totalDuration, Duration.zero);
      expect(s.average, Duration.zero);
    });

    test('counts only fasts with endAt inside the week window', () {
      final s = aggregateWeeklyFasting(
        fasts: [
          f(
            id: 1,
            startAt: DateTime(2026, 4, 25, 20),
            endAt: DateTime(2026, 4, 25, 23),
          ), // before week
          f(
            id: 2,
            startAt: DateTime(2026, 4, 26, 20),
            endAt: DateTime(2026, 4, 27, 12),
          ), // Monday endAt
          f(
            id: 3,
            startAt: DateTime(2026, 5, 2, 20),
            endAt: DateTime(2026, 5, 3, 12),
          ), // next week
        ],
        weekStart: weekStart,
      );
      expect(s.total, 1);
      expect(s.completed, 1);
      expect(s.totalDuration, const Duration(hours: 16));
      expect(s.average, const Duration(hours: 16));
    });

    test('average is total / days with fasts', () {
      final s = aggregateWeeklyFasting(
        fasts: [
          f(
            id: 1,
            startAt: DateTime(2026, 4, 26, 20),
            endAt: DateTime(2026, 4, 27, 12), // Mon endAt
          ),
          f(
            id: 2,
            startAt: DateTime(2026, 4, 28, 20),
            endAt: DateTime(2026, 4, 29, 12), // Wed endAt
          ),
        ],
        weekStart: weekStart,
      );
      expect(s.totalDuration, const Duration(hours: 32));
      expect(s.average, const Duration(hours: 16));
    });

    test('completed flag separates completed from total', () {
      final s = aggregateWeeklyFasting(
        fasts: [
          f(
            id: 1,
            startAt: DateTime(2026, 4, 26, 20),
            endAt: DateTime(2026, 4, 27, 12),
            completed: true,
          ),
          f(
            id: 2,
            startAt: DateTime(2026, 4, 28, 20),
            endAt: DateTime(2026, 4, 28, 22), // ended early
            completed: false,
          ),
        ],
        weekStart: weekStart,
      );
      expect(s.total, 2);
      expect(s.completed, 1);
    });
  });

  group('lastFinishedFast', () {
    test('null on empty list', () {
      expect(lastFinishedFast(const []), isNull);
    });

    test('returns the fast with most recent endAt', () {
      final older = Fast(
        id: 1,
        startAt: DateTime(2026, 4, 20, 20),
        endAt: DateTime(2026, 4, 21, 12),
        targetHours: 16,
        eatingHours: 8,
        completed: true,
      );
      final newer = Fast(
        id: 2,
        startAt: DateTime(2026, 4, 25, 20),
        endAt: DateTime(2026, 4, 26, 12),
        targetHours: 16,
        eatingHours: 8,
        completed: true,
      );
      expect(lastFinishedFast([older, newer]), newer);
      expect(lastFinishedFast([newer, older]), newer);
    });

    test('skips fasts with endAt == null', () {
      final active = Fast(
        id: 1,
        startAt: DateTime(2026, 4, 30, 8),
        endAt: null,
        targetHours: 16,
        eatingHours: 8,
        completed: false,
      );
      final finished = Fast(
        id: 2,
        startAt: DateTime(2026, 4, 25, 20),
        endAt: DateTime(2026, 4, 26, 12),
        targetHours: 16,
        eatingHours: 8,
        completed: true,
      );
      expect(lastFinishedFast([active, finished]), finished);
    });
  });
}
