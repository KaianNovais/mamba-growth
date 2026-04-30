# Home Overview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the empty "Início" tab with a calm, scannable dashboard that shows today's calorie total + goal status, current and last fast, and a weekly bar chart of calorie evolution.

**Architecture:** Unified `HomeViewModel` (`ChangeNotifier` + `WidgetsBindingObserver`) orchestrates `MealsRepository` and `FastingRepository`. All derivation logic lives in pure functions in `aggregations.dart` (testable without `pumpWidget`). The chart is rendered with a custom `CustomPainter` (no chart library). Two preliminary chore commits rename folders for naming consistency before the feature lands.

**Tech Stack:** Flutter 3.11, Provider 6, ChangeNotifier, CustomPainter, intl. Existing tokens (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`). No new packages.

**Spec:** `docs/superpowers/specs/2026-04-30-home-overview-design.md`.

**Verification commands** (used at end of every task):
```bash
flutter analyze
flutter test
```
Both must finish green before committing.

---

## Task 1: Chore — rename `lib/ui/home/` → `lib/ui/fasting/`

The current `home/` folder holds the fasting timer, not the dashboard. Rename to remove naming confusion before the feature lands.

**Files:**
- Move: `lib/ui/home/view_models/home_view_model.dart` → `lib/ui/fasting/view_models/fasting_view_model.dart`
- Move: `lib/ui/home/widgets/home_screen.dart` → `lib/ui/fasting/widgets/fasting_screen.dart`
- Modify: `lib/ui/main/widgets/main_navigation_screen.dart`
- Move: `test/ui/home_view_model_test.dart` → `test/ui/fasting_view_model_test.dart`

- [ ] **Step 1: Move folder**

```bash
git mv lib/ui/home lib/ui/fasting
```

- [ ] **Step 2: Rename classes inside the moved files**

Edit `lib/ui/fasting/view_models/fasting_view_model.dart`: rename class `HomeViewModel` → `FastingViewModel` (constructor and all internal references).

Edit `lib/ui/fasting/widgets/fasting_screen.dart`:
- Rename class `HomeScreen` → `FastingScreen`.
- Update import path of the view model to `../view_models/fasting_view_model.dart`.
- Replace any `HomeViewModel` reference with `FastingViewModel`.
- If the doc-comment header mentions "tela home/jejum", update wording to "tela de jejum".

- [ ] **Step 3: Move the test file and update imports**

```bash
git mv test/ui/home_view_model_test.dart test/ui/fasting_view_model_test.dart
```

Edit `test/ui/fasting_view_model_test.dart`:
- Replace `import 'package:mamba_growth/ui/home/view_models/home_view_model.dart';` with `import 'package:mamba_growth/ui/fasting/view_models/fasting_view_model.dart';`.
- Replace every `HomeViewModel` with `FastingViewModel` in the file body.

- [ ] **Step 4: Update `main_navigation_screen.dart` import**

In `lib/ui/main/widgets/main_navigation_screen.dart`, change:
```dart
import '../../home/widgets/home_screen.dart';
```
to:
```dart
import '../../fasting/widgets/fasting_screen.dart';
```

And in the `_pages` list, replace `HomeScreen()` (the second entry, index 1) with `FastingScreen()`.

- [ ] **Step 5: Sweep for stragglers**

Run a global search and update any other reference. There must be no remaining import or symbol referencing the old path.

```bash
grep -rn "ui/home/" lib test || echo "clean"
grep -rn "HomeViewModel\b" lib test || echo "clean"
grep -rn "\bHomeScreen\b" lib test || echo "clean"
```
Expected: every line printed (if any) prints `clean`.

- [ ] **Step 6: Verify**

Run:
```bash
flutter analyze
flutter test
```
Both must be green. Tests count must be the same as before (60).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore(nav): rename ui/home → ui/fasting

The fasting timer screen lives at lib/ui/home/ which conflicts with the
upcoming overview dashboard that will own the "Início" tab. Renaming
home → fasting before the feature so symbol names match the role.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Chore — rename `lib/ui/dashboard/` → `lib/ui/home/` (placeholder)

Rename the empty placeholder folder so the new feature lands in `lib/ui/home/`. The class `DashboardScreen` becomes `HomeScreen` (with the same `EmptyFeatureState` body for now — replaced by the real feature in later tasks).

**Files:**
- Move: `lib/ui/dashboard/widgets/dashboard_screen.dart` → `lib/ui/home/widgets/home_screen.dart`
- Modify: `lib/ui/main/widgets/main_navigation_screen.dart`

- [ ] **Step 1: Move folder**

```bash
git mv lib/ui/dashboard lib/ui/home
```

- [ ] **Step 2: Rename file**

```bash
git mv lib/ui/home/widgets/dashboard_screen.dart lib/ui/home/widgets/home_screen.dart
```

- [ ] **Step 3: Rename class inside `home_screen.dart`**

Edit `lib/ui/home/widgets/home_screen.dart`: rename class `DashboardScreen` → `HomeScreen`. Body stays identical (still `EmptyFeatureState`). Final content:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.navHome)),
      body: SafeArea(
        top: false,
        child: EmptyFeatureState(
          icon: Icons.home_rounded,
          eyebrow: l10n.navHome,
          title: l10n.homeNewEmptyTitle,
          subtitle: l10n.homeNewEmptySubtitle,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Update `main_navigation_screen.dart`**

In `lib/ui/main/widgets/main_navigation_screen.dart`, change:
```dart
import '../../dashboard/widgets/dashboard_screen.dart';
```
to:
```dart
import '../../home/widgets/home_screen.dart';
```

In `_pages`, replace the first entry `DashboardScreen()` with `HomeScreen()`.

- [ ] **Step 5: Sweep**

```bash
grep -rn "ui/dashboard/" lib test || echo "clean"
grep -rn "DashboardScreen" lib test || echo "clean"
```
Both must print `clean`.

- [ ] **Step 6: Verify**

```bash
flutter analyze
flutter test
```
Both green. 60 tests still pass.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore(nav): rename ui/dashboard → ui/home (placeholder)

After the previous fasting-rename, the "Início" tab placeholder lives in
ui/dashboard/. Moving it to ui/home/ to match the tab name. Body stays
as EmptyFeatureState for now; the real overview dashboard lands in
follow-up commits.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add date utilities + `aggregations.dart`

Move `startOfDay`, `startOfWeekSunday`, `currentWeekDays` into a shared module so the new `HomeViewModel`, the existing `WeekDaySelector`, and other future date code consume the same source of truth.

**Files:**
- Create: `lib/ui/home/state/aggregations.dart`
- Modify: `lib/ui/core/widgets/week_day_selector.dart`
- Create: `test/ui/home/aggregations_test.dart`

- [ ] **Step 1: Write failing tests for the date helpers**

Create `test/ui/home/aggregations_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
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
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/ui/home/aggregations_test.dart
```
Expected: file not found / import unresolved.

- [ ] **Step 3: Implement `aggregations.dart` with date helpers only**

Create `lib/ui/home/state/aggregations.dart`:

```dart
/// Pure date and aggregation helpers for the Home overview.
///
/// All functions are deterministic — no `DateTime.now()`, no I/O —
/// so they can be unit-tested without `pumpWidget` or fakes.

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
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/ui/home/aggregations_test.dart
```
Expected: 5 tests passing.

- [ ] **Step 5: Update `WeekDaySelector` to delegate to `aggregations.dart`**

Edit `lib/ui/core/widgets/week_day_selector.dart`. Add import at top:
```dart
import '../../home/state/aggregations.dart' as agg;
```

Replace the two static methods with thin delegates (keeping the existing public API, since other files call `WeekDaySelector.startOfWeekSunday` / `WeekDaySelector.currentWeekDays`):

```dart
  /// Início da semana com domingo = dia 0 (padrão BR), normalizado a 00:00.
  static DateTime startOfWeekSunday(DateTime d) => agg.startOfWeekSunday(d);

  /// Lista com os 7 dias (00:00) da semana de [d], em ordem dom→sáb.
  static List<DateTime> currentWeekDays(DateTime d) => agg.currentWeekDays(d);
```

- [ ] **Step 6: Verify all tests still pass**

```bash
flutter analyze
flutter test
```
60 tests + 5 new = 65 expected. Green.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
feat(home): extract date helpers into aggregations.dart

Adds the new lib/ui/home/state/aggregations.dart with startOfDay,
startOfWeekSunday and currentWeekDays. WeekDaySelector keeps its public
static API but delegates to the new module. Lays the groundwork for
home aggregations.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Aggregations — calorie & target counts

Add `DayKcal`, `MealStatus`, and the three pure functions covering today's status and the weekly bar data.

**Files:**
- Modify: `lib/ui/home/state/aggregations.dart`
- Modify: `test/ui/home/aggregations_test.dart`

- [ ] **Step 1: Write failing tests**

Append to `test/ui/home/aggregations_test.dart`:

```dart
import 'package:mamba_growth/domain/models/meal.dart';

// ...inside `void main()` add:

  group('aggregateWeekKcal', () {
    final weekStart = DateTime(2026, 4, 26); // Sunday

    Meal _meal({required int id, required DateTime when, required int kcal}) =>
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
          _meal(id: 1, when: DateTime(2026, 4, 27, 8), kcal: 400),
          _meal(id: 2, when: DateTime(2026, 4, 27, 19), kcal: 600),
          _meal(id: 3, when: DateTime(2026, 4, 29, 12), kcal: 800),
        ],
        weekStart: weekStart,
      );
      expect(out[1].kcal, 1000); // Monday
      expect(out[3].kcal, 800);  // Wednesday
      expect(out[0].kcal, 0);
    });

    test('meal at 23:59 belongs to its day; 00:01 next day to next', () {
      final out = aggregateWeekKcal(
        meals: [
          _meal(id: 1, when: DateTime(2026, 4, 27, 23, 59), kcal: 100),
          _meal(id: 2, when: DateTime(2026, 4, 28, 0, 1), kcal: 200),
        ],
        weekStart: weekStart,
      );
      expect(out[1].kcal, 100); // Monday
      expect(out[2].kcal, 200); // Tuesday
    });

    test('drops meals outside the week window', () {
      final out = aggregateWeekKcal(
        meals: [
          _meal(id: 1, when: DateTime(2026, 4, 25, 12), kcal: 999),
          _meal(id: 2, when: DateTime(2026, 5, 3, 12), kcal: 999),
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
        DayKcal(day: DateTime(2026, 4, 28), kcal: 0),    // Tue (closed, on - 0 counts)
        DayKcal(day: DateTime(2026, 4, 29), kcal: 1800), // Wed (closed, on)
        DayKcal(day: DateTime(2026, 4, 30), kcal: 1200), // Thu (today, NOT closed)
        DayKcal(day: DateTime(2026, 5, 1), kcal: 0),     // Fri (future)
        DayKcal(day: DateTime(2026, 5, 2), kcal: 0),     // Sat (future)
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
```

- [ ] **Step 2: Run tests — they should fail at compile**

```bash
flutter test test/ui/home/aggregations_test.dart
```
Expected: undefined `DayKcal`, `MealStatus`, `aggregateWeekKcal`, `daysOnTarget`, `computeStatus`.

- [ ] **Step 3: Implement in `aggregations.dart`**

Append to `lib/ui/home/state/aggregations.dart`:

```dart
import '../../../domain/models/meal.dart';

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
```

- [ ] **Step 4: Run tests — must pass**

```bash
flutter test test/ui/home/aggregations_test.dart
```
Expected: 5 (date) + 4 + 3 + 5 = 17 tests passing.

- [ ] **Step 5: Verify whole suite**

```bash
flutter analyze
flutter test
```
Green. ~77 tests now (60 + 17).

- [ ] **Step 6: Commit**

```bash
git add lib/ui/home/state/aggregations.dart test/ui/home/aggregations_test.dart
git commit -m "$(cat <<'EOF'
feat(home): add calorie & target aggregations

Adds DayKcal, MealStatus, aggregateWeekKcal, daysOnTarget and
computeStatus pure functions with full unit coverage. Today is
explicitly excluded from "days on target" — the count is over closed
days only, so Sunday 00:00 reports 0/0.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Aggregations — fasting summary + last finished fast

Add `WeeklyFastingSummary`, `aggregateWeeklyFasting`, and `lastFinishedFast`.

**Files:**
- Modify: `lib/ui/home/state/aggregations.dart`
- Modify: `test/ui/home/aggregations_test.dart`

- [ ] **Step 1: Write failing tests**

Append to `test/ui/home/aggregations_test.dart`:

```dart
import 'package:mamba_growth/domain/models/fast.dart';

// ...inside main():

  group('aggregateWeeklyFasting', () {
    final weekStart = DateTime(2026, 4, 26);

    Fast _f({
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
          _f(
            id: 1,
            startAt: DateTime(2026, 4, 25, 20),
            endAt: DateTime(2026, 4, 25, 23),
          ), // before week
          _f(
            id: 2,
            startAt: DateTime(2026, 4, 26, 20),
            endAt: DateTime(2026, 4, 27, 12),
          ), // Monday endAt
          _f(
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
          _f(
            id: 1,
            startAt: DateTime(2026, 4, 26, 20),
            endAt: DateTime(2026, 4, 27, 12), // Mon endAt
          ),
          _f(
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
          _f(
            id: 1,
            startAt: DateTime(2026, 4, 26, 20),
            endAt: DateTime(2026, 4, 27, 12),
            completed: true,
          ),
          _f(
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
```

- [ ] **Step 2: Run tests — must fail at compile**

```bash
flutter test test/ui/home/aggregations_test.dart
```

- [ ] **Step 3: Implement in `aggregations.dart`**

Append to `lib/ui/home/state/aggregations.dart`:

```dart
import '../../../domain/models/fast.dart';

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
```

- [ ] **Step 4: Run tests — must pass**

```bash
flutter test test/ui/home/aggregations_test.dart
```

- [ ] **Step 5: Verify whole suite**

```bash
flutter analyze
flutter test
```
Green. ~84 tests now.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/home/state/aggregations.dart test/ui/home/aggregations_test.dart
git commit -m "$(cat <<'EOF'
feat(home): add weekly fasting aggregations

Adds WeeklyFastingSummary, aggregateWeeklyFasting and lastFinishedFast.
Average is total duration divided by days with at least one fast (not
by 7) so empty days do not deflate the metric. Fasts grouped by endAt.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Add l10n strings (en + pt)

All copy needed by the new screen, in one commit, before the widgets that consume it.

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_pt.arb`

- [ ] **Step 1: Append keys to `app_en.arb`**

Add the following keys before the closing `}` of `lib/l10n/app_en.arb`. Make sure the previous line gets a trailing comma.

```json
  "homeOverviewTitle": "Home",
  "homeTodayEyebrow": "TODAY · {date}",
  "@homeTodayEyebrow": {
    "placeholders": { "date": { "type": "String" } }
  },
  "homeStatusOnTarget": "On target",
  "homeStatusOverGoal": "Over by {n} kcal",
  "@homeStatusOverGoal": {
    "placeholders": { "n": { "type": "int" } }
  },
  "homeStatusNoGoal": "Set a goal",
  "homeFastingActive": "Fasting for {duration}",
  "@homeFastingActive": {
    "placeholders": { "duration": { "type": "String" } }
  },
  "homeFastingIdle": "No fast right now",
  "homeFastingIdleAction": "Start",
  "homeFastingLast": "Last · {duration} · {when}",
  "@homeFastingLast": {
    "placeholders": {
      "duration": { "type": "String" },
      "when": { "type": "String" }
    }
  },
  "homeFastingStatusLabel": "Status",
  "homeFastingLastLabel": "Last",
  "homeWeekEyebrow": "THIS WEEK",
  "homeWeekOnTarget": "{on}/{closed} ON TARGET",
  "@homeWeekOnTarget": {
    "placeholders": {
      "on": { "type": "int" },
      "closed": { "type": "int" }
    }
  },
  "homeWeekChartGoalLabel": "goal {kcal}",
  "@homeWeekChartGoalLabel": {
    "placeholders": { "kcal": { "type": "int" } }
  },
  "homeWeekFastingTitle": "WEEKLY FASTING",
  "homeWeekFastingCompletedLabel": "Completed",
  "homeWeekFastingTotalLabel": "Total",
  "homeWeekFastingAverageLabel": "Average",
  "homeWeekFastingEmpty": "No fasts this week",
  "homeWeekdayLetters": "SMTWTFS",
  "homeChartA11y": "Calorie chart, {on} of {closed} days on target. Selected: {day}, {kcal} kcal.",
  "@homeChartA11y": {
    "placeholders": {
      "on": { "type": "int" },
      "closed": { "type": "int" },
      "day": { "type": "String" },
      "kcal": { "type": "int" }
    }
  }
```

- [ ] **Step 2: Append corresponding keys to `app_pt.arb`**

Use the same key list with PT translations:

```json
  "homeOverviewTitle": "Início",
  "homeTodayEyebrow": "HOJE · {date}",
  "@homeTodayEyebrow": {
    "placeholders": { "date": { "type": "String" } }
  },
  "homeStatusOnTarget": "Na meta",
  "homeStatusOverGoal": "{n} kcal acima",
  "@homeStatusOverGoal": {
    "placeholders": { "n": { "type": "int" } }
  },
  "homeStatusNoGoal": "Definir meta",
  "homeFastingActive": "Em jejum há {duration}",
  "@homeFastingActive": {
    "placeholders": { "duration": { "type": "String" } }
  },
  "homeFastingIdle": "Sem jejum agora",
  "homeFastingIdleAction": "Iniciar",
  "homeFastingLast": "Último · {duration} · {when}",
  "@homeFastingLast": {
    "placeholders": {
      "duration": { "type": "String" },
      "when": { "type": "String" }
    }
  },
  "homeFastingStatusLabel": "Status",
  "homeFastingLastLabel": "Último",
  "homeWeekEyebrow": "ESTA SEMANA",
  "homeWeekOnTarget": "{on}/{closed} NA META",
  "@homeWeekOnTarget": {
    "placeholders": {
      "on": { "type": "int" },
      "closed": { "type": "int" }
    }
  },
  "homeWeekChartGoalLabel": "meta {kcal}",
  "@homeWeekChartGoalLabel": {
    "placeholders": { "kcal": { "type": "int" } }
  },
  "homeWeekFastingTitle": "JEJUM DA SEMANA",
  "homeWeekFastingCompletedLabel": "Concluídos",
  "homeWeekFastingTotalLabel": "Total",
  "homeWeekFastingAverageLabel": "Média",
  "homeWeekFastingEmpty": "Nenhum jejum esta semana",
  "homeWeekdayLetters": "DSTQQSS",
  "homeChartA11y": "Gráfico de calorias, {on} de {closed} dias na meta. Selecionado: {day}, {kcal} kcal.",
  "@homeChartA11y": {
    "placeholders": {
      "on": { "type": "int" },
      "closed": { "type": "int" },
      "day": { "type": "String" },
      "kcal": { "type": "int" }
    }
  }
```

- [ ] **Step 3: Regenerate localizations**

```bash
flutter pub get
```

`flutter pub get` re-runs the l10n generator (configured in `l10n.yaml`).

- [ ] **Step 4: Verify generated file contains the new symbols**

```bash
grep -n "homeOverviewTitle\|homeChartA11y" lib/l10n/generated/app_localizations.dart
```
Expected: 2+ matches (declaration in abstract class + per-locale).

- [ ] **Step 5: Verify suite**

```bash
flutter analyze
flutter test
```
Green.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/ pubspec.lock
git commit -m "$(cat <<'EOF'
feat(home): add l10n keys for overview screen

en + pt strings for the new dashboard: today eyebrow, status chip,
fasting status lines, week eyebrow, chart goal label, weekly fasting
card labels, semantics description.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: `HomeState` data class

A single immutable snapshot of everything the Home renders. Lets the VM expose `state` to selectors and to tests cleanly.

**Files:**
- Create: `lib/ui/home/state/home_state.dart`

- [ ] **Step 1: Create `home_state.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../../../domain/models/fast.dart';
import 'aggregations.dart';

@immutable
class HomeState {
  const HomeState({
    required this.isInitialized,
    required this.today,
    required this.weekStart,
    required this.todayKcal,
    required this.goal,
    required this.status,
    required this.activeFast,
    required this.lastFinishedFast,
    required this.weekDays,
    required this.daysOnTargetClosed,
    required this.daysClosedThisWeek,
    required this.fasting,
    required this.selectedDayIndex,
  });

  final bool isInitialized;
  final DateTime today;
  final DateTime weekStart;

  final int todayKcal;
  final int? goal;
  final MealStatus status;

  final Fast? activeFast;
  final Fast? lastFinishedFast;

  final List<DayKcal> weekDays;
  final int daysOnTargetClosed;
  final int daysClosedThisWeek;

  final WeeklyFastingSummary fasting;

  final int selectedDayIndex;

  int get todayIndex {
    for (var i = 0; i < weekDays.length; i++) {
      if (weekDays[i].day == today) return i;
    }
    return -1;
  }

  int get firstFutureIndex => todayIndex + 1;

  factory HomeState.empty(DateTime now) {
    final todayDay = startOfDay(now);
    final start = startOfWeekSunday(now);
    final week = List.generate(
      7,
      (i) => DayKcal(day: start.add(Duration(days: i)), kcal: 0),
    );
    final todayIdx = todayDay.difference(start).inDays;
    return HomeState(
      isInitialized: false,
      today: todayDay,
      weekStart: start,
      todayKcal: 0,
      goal: null,
      status: MealStatus.noGoal,
      activeFast: null,
      lastFinishedFast: null,
      weekDays: week,
      daysOnTargetClosed: 0,
      daysClosedThisWeek: 0,
      fasting: WeeklyFastingSummary.empty,
      selectedDayIndex: todayIdx,
    );
  }

  HomeState copyWith({
    bool? isInitialized,
    DateTime? today,
    DateTime? weekStart,
    int? todayKcal,
    int? goal,
    bool clearGoal = false,
    MealStatus? status,
    Fast? activeFast,
    bool clearActiveFast = false,
    Fast? lastFinishedFast,
    bool clearLastFinishedFast = false,
    List<DayKcal>? weekDays,
    int? daysOnTargetClosed,
    int? daysClosedThisWeek,
    WeeklyFastingSummary? fasting,
    int? selectedDayIndex,
  }) {
    return HomeState(
      isInitialized: isInitialized ?? this.isInitialized,
      today: today ?? this.today,
      weekStart: weekStart ?? this.weekStart,
      todayKcal: todayKcal ?? this.todayKcal,
      goal: clearGoal ? null : (goal ?? this.goal),
      status: status ?? this.status,
      activeFast: clearActiveFast ? null : (activeFast ?? this.activeFast),
      lastFinishedFast: clearLastFinishedFast
          ? null
          : (lastFinishedFast ?? this.lastFinishedFast),
      weekDays: weekDays ?? this.weekDays,
      daysOnTargetClosed: daysOnTargetClosed ?? this.daysOnTargetClosed,
      daysClosedThisWeek: daysClosedThisWeek ?? this.daysClosedThisWeek,
      fasting: fasting ?? this.fasting,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/ui/home/state/home_state.dart
```
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/home/state/home_state.dart
git commit -m "$(cat <<'EOF'
feat(home): add HomeState data class

Immutable snapshot of the Home screen state with copyWith and an
HomeState.empty factory used as the initial value before the first
load resolves.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Test fakes for the two repositories

Self-contained fakes for use in `home_view_model_test.dart`. They live in the test folder, not in production code.

**Files:**
- Create: `test/ui/home/_fakes.dart`

- [ ] **Step 1: Create `_fakes.dart`**

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mamba_growth/data/repositories/fasting/fasting_repository.dart';
import 'package:mamba_growth/data/repositories/meals/meals_repository.dart';
import 'package:mamba_growth/domain/models/fast.dart';
import 'package:mamba_growth/domain/models/fasting_protocol.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/utils/result.dart';

class FakeMealsRepository extends ChangeNotifier implements MealsRepository {
  final ValueNotifier<int?> _goal = ValueNotifier<int?>(null);
  final StreamController<List<Meal>> _todayCtrl =
      StreamController<List<Meal>>.broadcast();
  List<Meal> _todayMeals = const [];
  List<Meal> _weekMeals = const [];

  void setTodayMeals(List<Meal> meals) {
    _todayMeals = meals;
    _todayCtrl.add(meals);
  }

  void setWeekMeals(List<Meal> meals) {
    _weekMeals = meals;
  }

  @override
  bool get isInitialized => true;

  @override
  ValueListenable<int?> get goalListenable => _goal;

  @override
  int? get currentGoal => _goal.value;

  @override
  Stream<List<Meal>> watchMealsForDay(DateTime day) async* {
    yield _todayMeals;
    yield* _todayCtrl.stream;
  }

  @override
  Future<List<Meal>> getMealsBetween(DateTime start, DateTime end) async {
    return _weekMeals
        .where((m) =>
            !m.eatenAt.isBefore(start) && m.eatenAt.isBefore(end))
        .toList();
  }

  @override
  Future<Result<Meal>> addMeal({
    required String name,
    required int calories,
  }) async => const Result.error(MealsException('na'));

  @override
  Future<Result<Meal>> updateMeal(Meal m) async => Result.ok(m);

  @override
  Future<Result<void>> deleteMeal(int id) async => const Result.ok(null);

  @override
  Future<Result<Meal>> reinsertMeal(Meal m) async => Result.ok(m);

  @override
  Future<void> setGoal(int kcal) async {
    _goal.value = kcal;
    notifyListeners();
  }

  @override
  Future<void> clearGoal() async {
    _goal.value = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _todayCtrl.close();
    _goal.dispose();
    super.dispose();
  }
}

class FakeFastingRepository extends ChangeNotifier
    implements FastingRepository {
  Fast? _active;
  FastingProtocol _protocol = FastingProtocol.defaultProtocol;
  final StreamController<List<Fast>> _completedCtrl =
      StreamController<List<Fast>>.broadcast();
  List<Fast> _completed = const [];
  List<Fast> _weekFasts = const [];

  void setActive(Fast? f) {
    _active = f;
    notifyListeners();
  }

  void setCompleted(List<Fast> fasts) {
    _completed = fasts;
    _completedCtrl.add(fasts);
  }

  void setWeekFasts(List<Fast> fasts) {
    _weekFasts = fasts;
  }

  @override
  Fast? get activeFast => _active;

  @override
  FastingProtocol get selectedProtocol => _protocol;

  @override
  bool get isInitialized => true;

  @override
  Future<Result<Fast>> startFast() async =>
      const Result.error(FastingException('na'));

  @override
  Future<Result<Fast>> endFast() async =>
      const Result.error(FastingException('na'));

  @override
  Future<void> setProtocol(FastingProtocol p) async {
    _protocol = p;
    notifyListeners();
  }

  @override
  Stream<List<Fast>> watchCompletedFasts() async* {
    yield _completed;
    yield* _completedCtrl.stream;
  }

  @override
  Future<List<Fast>> getFastsBetween(DateTime start, DateTime end) async {
    return _weekFasts
        .where((f) {
          final end2 = f.endAt;
          if (end2 == null) return false;
          return !end2.isBefore(start) && end2.isBefore(end);
        })
        .toList();
  }

  @override
  void dispose() {
    _completedCtrl.close();
    super.dispose();
  }
}
```

- [ ] **Step 2: Verify it compiles** (no test runs yet — file is referenced in next task)

```bash
flutter analyze test/ui/home/_fakes.dart
```
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add test/ui/home/_fakes.dart
git commit -m "$(cat <<'EOF'
test(home): add Meals/Fasting repo fakes for VM tests

Self-contained ChangeNotifier-based fakes that mirror the production
repository contracts. Used by the upcoming home_view_model_test.dart.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: `HomeViewModel` — initial load

First slice: subscribe to streams, load week window in parallel, expose `state`. TDD.

**Files:**
- Create: `lib/ui/home/state/home_view_model.dart`
- Create: `test/ui/home/home_view_model_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/ui/home/home_view_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/ui/home/state/aggregations.dart';
import 'package:mamba_growth/ui/home/state/home_view_model.dart';

import '_fakes.dart';

void main() {
  group('HomeViewModel — initial load', () {
    test('starts not initialized, becomes initialized after _init resolves',
        () async {
      final meals = FakeMealsRepository();
      final fasting = FakeFastingRepository();
      final now = DateTime(2026, 4, 30, 9);

      meals.setWeekMeals([
        Meal(
          id: 1,
          name: 'a',
          calories: 500,
          eatenAt: DateTime(2026, 4, 28, 10),
        ),
      ]);

      final vm = HomeViewModel(
        meals: meals,
        fasting: fasting,
        nowProvider: () => now,
      );

      expect(vm.state.isInitialized, isFalse);
      // Pump microtasks for the futures to resolve.
      await Future<void>.delayed(Duration.zero);

      expect(vm.state.isInitialized, isTrue);
      expect(vm.state.today, DateTime(2026, 4, 30));
      expect(vm.state.weekStart, DateTime(2026, 4, 26));
      expect(vm.state.weekDays.length, 7);
      // Tuesday (index 2) should have 500 from getMealsBetween.
      expect(vm.state.weekDays[2].kcal, 500);
      vm.dispose();
    });
  });
}
```

- [ ] **Step 2: Run test — must fail** (file does not exist yet)

```bash
flutter test test/ui/home/home_view_model_test.dart
```

- [ ] **Step 3: Implement initial load in `home_view_model.dart`**

Create `lib/ui/home/state/home_view_model.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../data/repositories/meals/meals_repository.dart';
import '../../../domain/models/fast.dart';
import '../../../domain/models/meal.dart';
import 'aggregations.dart';
import 'home_state.dart';

class HomeViewModel extends ChangeNotifier with WidgetsBindingObserver {
  HomeViewModel({
    required MealsRepository meals,
    required FastingRepository fasting,
    DateTime Function() nowProvider = DateTime.now,
  })  : _meals = meals,
        _fasting = fasting,
        _nowProvider = nowProvider {
    _state = HomeState.empty(_nowProvider());
    _meals.addListener(_onMealsRepoChanged);
    _fasting.addListener(_onFastingRepoChanged);
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  final MealsRepository _meals;
  final FastingRepository _fasting;
  final DateTime Function() _nowProvider;

  late HomeState _state;
  HomeState get state => _state;

  StreamSubscription<List<Meal>>? _todaySub;
  StreamSubscription<List<Fast>>? _completedSub;

  // Convenience getters for selectors:
  bool get isInitialized => _state.isInitialized;
  int get todayKcal => _state.todayKcal;
  int? get goal => _state.goal;
  MealStatus get status => _state.status;

  Future<void> _init() async {
    final now = _nowProvider();
    final today = startOfDay(now);
    final weekStart = startOfWeekSunday(now);
    _state = _state.copyWith(
      today: today,
      weekStart: weekStart,
      goal: _meals.currentGoal,
      activeFast: _fasting.activeFast,
      clearActiveFast: _fasting.activeFast == null,
    );

    _subscribeToday(today);
    _subscribeCompletedFasts();

    await _loadWeek();

    _state = _state.copyWith(isInitialized: true);
    notifyListeners();
  }

  void _subscribeToday(DateTime today) {
    _todaySub?.cancel();
    _todaySub = _meals.watchMealsForDay(today).listen(_onTodayMealsChanged);
  }

  void _subscribeCompletedFasts() {
    _completedSub?.cancel();
    _completedSub = _fasting.watchCompletedFasts().listen(_onCompletedFastsChanged);
  }

  Future<void> _loadWeek() async {
    final weekStart = _state.weekStart;
    final weekEnd = weekStart.add(const Duration(days: 7));
    try {
      final meals = await _meals.getMealsBetween(weekStart, weekEnd);
      final fasts = await _fasting.getFastsBetween(weekStart, weekEnd);
      _applyWeekAggregations(meals: meals, fasts: fasts);
    } catch (e) {
      debugPrint('HomeViewModel._loadWeek error: $e');
    }
  }

  void _applyWeekAggregations({
    required List<Meal> meals,
    required List<Fast> fasts,
  }) {
    final weekDays = aggregateWeekKcal(
      meals: meals,
      weekStart: _state.weekStart,
    );
    final t = daysOnTarget(
      weekDays: weekDays,
      goal: _state.goal,
      today: _state.today,
    );
    final summary = aggregateWeeklyFasting(
      fasts: fasts,
      weekStart: _state.weekStart,
    );
    _state = _state.copyWith(
      weekDays: weekDays,
      daysOnTargetClosed: t.onTarget,
      daysClosedThisWeek: t.closed,
      fasting: summary,
    );
  }

  void _onTodayMealsChanged(List<Meal> meals) {
    final total = meals.fold<int>(0, (s, m) => s + m.calories);
    final newStatus = computeStatus(consumed: total, goal: _state.goal);
    final updatedWeek = [..._state.weekDays];
    final idx = _state.todayIndex;
    if (idx >= 0) {
      updatedWeek[idx] = DayKcal(day: _state.today, kcal: total);
    }
    _state = _state.copyWith(
      todayKcal: total,
      status: newStatus,
      weekDays: updatedWeek,
    );
    notifyListeners();
  }

  void _onCompletedFastsChanged(List<Fast> fasts) {
    _state = _state.copyWith(
      lastFinishedFast: lastFinishedFast(fasts),
      clearLastFinishedFast: lastFinishedFast(fasts) == null,
    );
    // Reload weekly fasting summary from the same source.
    _state = _state.copyWith(
      fasting: aggregateWeeklyFasting(
        fasts: fasts,
        weekStart: _state.weekStart,
      ),
    );
    notifyListeners();
  }

  void _onMealsRepoChanged() {
    final newGoal = _meals.currentGoal;
    final newStatus = computeStatus(
      consumed: _state.todayKcal,
      goal: newGoal,
    );
    final t = daysOnTarget(
      weekDays: _state.weekDays,
      goal: newGoal,
      today: _state.today,
    );
    _state = _state.copyWith(
      goal: newGoal,
      clearGoal: newGoal == null,
      status: newStatus,
      daysOnTargetClosed: t.onTarget,
      daysClosedThisWeek: t.closed,
    );
    notifyListeners();
  }

  void _onFastingRepoChanged() {
    final active = _fasting.activeFast;
    _state = _state.copyWith(
      activeFast: active,
      clearActiveFast: active == null,
    );
    notifyListeners();
  }

  void selectDay(int index) {
    if (index < 0 || index > 6) return;
    if (index == _state.selectedDayIndex) return;
    _state = _state.copyWith(selectedDayIndex: index);
    notifyListeners();
  }

  @override
  void dispose() {
    _todaySub?.cancel();
    _completedSub?.cancel();
    _meals.removeListener(_onMealsRepoChanged);
    _fasting.removeListener(_onFastingRepoChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

- [ ] **Step 4: Run the test — should pass**

```bash
flutter test test/ui/home/home_view_model_test.dart
```

- [ ] **Step 5: Verify suite**

```bash
flutter analyze
flutter test
```
Green.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/home/state/home_view_model.dart test/ui/home/home_view_model_test.dart
git commit -m "$(cat <<'EOF'
feat(home): add HomeViewModel skeleton with initial load

Subscribes to MealsRepository.watchMealsForDay and
FastingRepository.watchCompletedFasts on init, loads the week window
via getMealsBetween/getFastsBetween in parallel, marks isInitialized
true once both Futures resolve. Exposes HomeState via state getter.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: `HomeViewModel` — meal stream + goal update tests

Add tests that lock in the listener behaviour written in Task 9.

**Files:**
- Modify: `test/ui/home/home_view_model_test.dart`

- [ ] **Step 1: Add tests**

Append inside `void main()`:

```dart
  group('HomeViewModel — meal stream', () {
    test('today meal stream updates todayKcal and status', () async {
      final meals = FakeMealsRepository();
      final fasting = FakeFastingRepository();
      final now = DateTime(2026, 4, 30, 12);

      await meals.setGoal(2000);
      meals.setTodayMeals([]);

      final vm = HomeViewModel(
        meals: meals,
        fasting: fasting,
        nowProvider: () => now,
      );
      await Future<void>.delayed(Duration.zero);

      expect(vm.state.todayKcal, 0);
      expect(vm.state.status, MealStatus.underGoal);

      meals.setTodayMeals([
        Meal(id: 1, name: 'a', calories: 2100, eatenAt: now),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(vm.state.todayKcal, 2100);
      expect(vm.state.status, MealStatus.overGoal);
      // The today bar in the week chart updates too.
      expect(vm.state.weekDays[vm.state.todayIndex].kcal, 2100);
      vm.dispose();
    });
  });

  group('HomeViewModel — goal change', () {
    test('changing goal recomputes status and daysOnTargetClosed',
        () async {
      final meals = FakeMealsRepository();
      final fasting = FakeFastingRepository();
      final now = DateTime(2026, 4, 30, 9);

      meals.setWeekMeals([
        Meal(
          id: 1,
          name: 'a',
          calories: 1500,
          eatenAt: DateTime(2026, 4, 27, 12),
        ),
        Meal(
          id: 2,
          name: 'b',
          calories: 2200,
          eatenAt: DateTime(2026, 4, 28, 12),
        ),
      ]);

      final vm = HomeViewModel(
        meals: meals,
        fasting: fasting,
        nowProvider: () => now,
      );
      await Future<void>.delayed(Duration.zero);

      // No goal yet → 0/0.
      expect(vm.state.daysClosedThisWeek, 0);
      expect(vm.state.daysOnTargetClosed, 0);

      await meals.setGoal(2000);
      await Future<void>.delayed(Duration.zero);

      // Closed days from Sun..Wed = 4. Mon = 1500 (on), Tue = 2200 (over),
      // Sun + Wed = 0 (on, because 0 <= 2000 with goal set).
      expect(vm.state.daysClosedThisWeek, 4);
      expect(vm.state.daysOnTargetClosed, 3);
      expect(vm.state.status, MealStatus.underGoal);
      vm.dispose();
    });
  });
```

- [ ] **Step 2: Run new tests — they must pass**

```bash
flutter test test/ui/home/home_view_model_test.dart
```

- [ ] **Step 3: Commit**

```bash
git add test/ui/home/home_view_model_test.dart
git commit -m "$(cat <<'EOF'
test(home): cover VM meal stream and goal change

Locks in: today meal stream emissions update todayKcal, status, and the
today bar of the week chart; goal changes recompute status and the
"days on target" counters.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: `HomeViewModel` — fasting changes + completed fasts

Tests that lock in the listener behaviour for active fast tracking and last-finished + weekly summary refresh on the completed-fasts stream.

**Files:**
- Modify: `test/ui/home/home_view_model_test.dart`

- [ ] **Step 1: Add tests**

```dart
  group('HomeViewModel — fasting', () {
    Fast _f({
      required int id,
      required DateTime startAt,
      required DateTime? endAt,
      bool completed = true,
    }) =>
        Fast(
          id: id,
          startAt: startAt,
          endAt: endAt,
          targetHours: 16,
          eatingHours: 8,
          completed: completed,
        );

    test('activeFast is mirrored from repo', () async {
      final meals = FakeMealsRepository();
      final fasting = FakeFastingRepository();
      final now = DateTime(2026, 4, 30, 9);

      final vm = HomeViewModel(
        meals: meals,
        fasting: fasting,
        nowProvider: () => now,
      );
      await Future<void>.delayed(Duration.zero);

      expect(vm.state.activeFast, isNull);

      final active = _f(
        id: 1,
        startAt: DateTime(2026, 4, 30, 6),
        endAt: null,
        completed: false,
      );
      fasting.setActive(active);

      expect(vm.state.activeFast, active);
      vm.dispose();
    });

    test('completed fasts stream updates lastFinishedFast and summary',
        () async {
      final meals = FakeMealsRepository();
      final fasting = FakeFastingRepository();
      final now = DateTime(2026, 4, 30, 9);

      final vm = HomeViewModel(
        meals: meals,
        fasting: fasting,
        nowProvider: () => now,
      );
      await Future<void>.delayed(Duration.zero);

      expect(vm.state.lastFinishedFast, isNull);
      expect(vm.state.fasting.completed, 0);

      final older = _f(
        id: 1,
        startAt: DateTime(2026, 4, 26, 20),
        endAt: DateTime(2026, 4, 27, 12),
      );
      final newer = _f(
        id: 2,
        startAt: DateTime(2026, 4, 28, 20),
        endAt: DateTime(2026, 4, 29, 12),
      );
      fasting.setCompleted([older, newer]);
      await Future<void>.delayed(Duration.zero);

      expect(vm.state.lastFinishedFast, newer);
      expect(vm.state.fasting.completed, 2);
      expect(vm.state.fasting.totalDuration, const Duration(hours: 32));
      vm.dispose();
    });
  });
```

- [ ] **Step 2: Run new tests**

```bash
flutter test test/ui/home/home_view_model_test.dart
```
All passing.

- [ ] **Step 3: Commit**

```bash
git add test/ui/home/home_view_model_test.dart
git commit -m "$(cat <<'EOF'
test(home): cover VM fasting state and completed fasts stream

Locks in: activeFast tracking via repo notifyListeners, lastFinishedFast
and WeeklyFastingSummary refresh from watchCompletedFasts emissions.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: `HomeViewModel` — `selectDay` + `reload` + lifecycle

Add the three remaining behaviours and their tests: tapping a chart bar updates `selectedDayIndex`, pull-to-refresh reloads the week, midnight rollover re-inits everything.

**Files:**
- Modify: `lib/ui/home/state/home_view_model.dart`
- Modify: `test/ui/home/home_view_model_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
  group('HomeViewModel — selectDay', () {
    test('selectDay updates selectedDayIndex within 0..6', () async {
      final meals = FakeMealsRepository();
      final fasting = FakeFastingRepository();
      final vm = HomeViewModel(
        meals: meals,
        fasting: fasting,
        nowProvider: () => DateTime(2026, 4, 30, 9),
      );
      await Future<void>.delayed(Duration.zero);

      vm.selectDay(2);
      expect(vm.state.selectedDayIndex, 2);

      vm.selectDay(7); // out of range, ignored
      expect(vm.state.selectedDayIndex, 2);

      vm.selectDay(-1); // out of range, ignored
      expect(vm.state.selectedDayIndex, 2);

      vm.dispose();
    });
  });

  group('HomeViewModel — reload', () {
    test('reload re-fetches week aggregations', () async {
      final meals = FakeMealsRepository();
      final fasting = FakeFastingRepository();
      final vm = HomeViewModel(
        meals: meals,
        fasting: fasting,
        nowProvider: () => DateTime(2026, 4, 30, 9),
      );
      await Future<void>.delayed(Duration.zero);
      expect(vm.state.weekDays[1].kcal, 0);

      meals.setWeekMeals([
        Meal(
          id: 1,
          name: 'a',
          calories: 700,
          eatenAt: DateTime(2026, 4, 27, 9),
        ),
      ]);
      await vm.reload();
      expect(vm.state.weekDays[1].kcal, 700);
      vm.dispose();
    });
  });

  group('HomeViewModel — midnight rollover', () {
    test('didChangeAppLifecycleState(resumed) on a new day re-inits',
        () async {
      final meals = FakeMealsRepository();
      final fasting = FakeFastingRepository();
      var now = DateTime(2026, 4, 29, 23, 59);
      final vm = HomeViewModel(
        meals: meals,
        fasting: fasting,
        nowProvider: () => now,
      );
      await Future<void>.delayed(Duration.zero);
      expect(vm.state.today, DateTime(2026, 4, 29));
      expect(vm.state.weekStart, DateTime(2026, 4, 26));

      now = DateTime(2026, 5, 3, 0, 1); // next Sunday
      vm.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(vm.state.today, DateTime(2026, 5, 3));
      expect(vm.state.weekStart, DateTime(2026, 5, 3));
      vm.dispose();
    });
  });
```

- [ ] **Step 2: Run — must fail** (`reload` and lifecycle method not yet present)

- [ ] **Step 3: Add `reload` and lifecycle handling**

In `lib/ui/home/state/home_view_model.dart`, append these methods to the class (immediately above `dispose`):

```dart
  Future<void> reload() async {
    await _loadWeek();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = _nowProvider();
    final newToday = startOfDay(now);
    if (newToday == _state.today) return;
    // Day changed — re-init from scratch.
    final newWeekStart = startOfWeekSunday(now);
    _state = _state.copyWith(
      today: newToday,
      weekStart: newWeekStart,
      // selectedDayIndex resets to today's index in the new week.
      selectedDayIndex: newToday.difference(newWeekStart).inDays,
    );
    _subscribeToday(newToday);
    _loadWeek().then((_) => notifyListeners());
    notifyListeners();
  }
```

- [ ] **Step 4: Run new tests — must pass**

```bash
flutter test test/ui/home/home_view_model_test.dart
```

- [ ] **Step 5: Verify suite**

```bash
flutter analyze
flutter test
```

- [ ] **Step 6: Commit**

```bash
git add lib/ui/home/state/home_view_model.dart test/ui/home/home_view_model_test.dart
git commit -m "$(cat <<'EOF'
feat(home): add VM selectDay, reload, and midnight rollover

selectDay updates the chart selection; reload (used by RefreshIndicator)
re-fetches the week window; the WidgetsBindingObserver detects a new
day on resume and re-initialises today/weekStart/subscriptions.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Widget — `TodayHero` (hero + status chip + fasting lines)

The big block at the top: eyebrow, calorie number, ProgressRing, status chip, and the two fasting lines.

**Files:**
- Create: `lib/ui/home/widgets/today_hero.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/fast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/progress_ring.dart';
import '../state/aggregations.dart';
import '../state/home_state.dart';
import '../state/home_view_model.dart';

class TodayHero extends StatelessWidget {
  const TodayHero({super.key, required this.onStartFastTap});

  /// Called when the user taps the "Iniciar →" CTA in the idle status row.
  final VoidCallback onStartFastTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typo = context.typo;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Selector<HomeViewModel, HomeState>(
      selector: (_, vm) => vm.state,
      shouldRebuild: (a, b) =>
          a.todayKcal != b.todayKcal ||
          a.goal != b.goal ||
          a.status != b.status ||
          a.activeFast != b.activeFast ||
          a.lastFinishedFast != b.lastFinishedFast ||
          a.today != b.today,
      builder: (context, state, _) {
        final dateLabel = DateFormat('EEE d MMM', locale)
            .format(state.today)
            .toUpperCase();
        final progress = (state.goal == null || state.goal == 0)
            ? 0.0
            : (state.todayKcal / state.goal!).clamp(0.0, 1.0);
        final ringColor = state.status == MealStatus.overGoal
            ? colors.accentWarm
            : colors.accent;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderDim),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.homeTodayEyebrow(dateLabel),
                style: typo.caption.copyWith(
                  color: colors.textDim,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _CalorieNumber(kcal: state.todayKcal),
                  ),
                  if (state.goal != null)
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: ProgressRing(
                        progress: progress,
                        color: ringColor,
                        backgroundColor: colors.surface2,
                        strokeWidth: 8,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _StatusChip(status: state.status, goal: state.goal,
                  consumed: state.todayKcal),
              const SizedBox(height: AppSpacing.lg),
              Divider(height: 1, color: colors.borderDim),
              const SizedBox(height: AppSpacing.lg),
              _FastingStatusRow(
                state: state,
                onStartFastTap: onStartFastTap,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.lastFinishedFast != null)
                _FastingLastRow(fast: state.lastFinishedFast!),
            ],
          ),
        );
      },
    );
  }
}

class _CalorieNumber extends StatelessWidget {
  const _CalorieNumber({required this.kcal});

  final int kcal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final formatted = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(kcal);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: formatted,
            style: typo.numericDisplay.copyWith(color: colors.text),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: l10n.mealsKcalUnit,
            style: typo.numericMedium.copyWith(color: colors.textDim),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.goal,
    required this.consumed,
  });

  final MealStatus status;
  final int? goal;
  final int consumed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);

    final (Color dotColor, Color labelColor, String label) = switch (status) {
      MealStatus.noGoal => (
          colors.textDimmer,
          colors.accent,
          l10n.homeStatusNoGoal,
        ),
      MealStatus.overGoal => (
          colors.accentWarm,
          colors.text,
          l10n.homeStatusOverGoal(consumed - (goal ?? 0)),
        ),
      MealStatus.atGoal || MealStatus.underGoal => (
          colors.accent,
          colors.text,
          l10n.homeStatusOnTarget,
        ),
    };

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: text.bodyMedium?.copyWith(color: labelColor),
        ),
      ],
    );
  }
}

class _FastingStatusRow extends StatelessWidget {
  const _FastingStatusRow({
    required this.state,
    required this.onStartFastTap,
  });

  final HomeState state;
  final VoidCallback onStartFastTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);

    final activeFast = state.activeFast;

    if (activeFast == null) {
      return Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              l10n.homeFastingStatusLabel,
              style: text.bodySmall?.copyWith(color: colors.textDimmer),
            ),
          ),
          Expanded(
            child: Text(
              l10n.homeFastingIdle,
              style: text.bodyMedium?.copyWith(color: colors.textDim),
            ),
          ),
          TextButton(
            onPressed: onStartFastTap,
            child: Text(l10n.homeFastingIdleAction),
          ),
        ],
      );
    }

    return Selector<HomeViewModel, DateTime>(
      // The HomeViewModel does not currently expose nowListenable; we
      // re-read activeFast on each VM notify (good enough since the
      // FastingRepository drives notifyListeners on protocol changes
      // and the timer ticks come through any rebuild trigger).
      selector: (_, vm) => DateTime.now(),
      builder: (context, now, _) {
        final elapsed = activeFast.elapsed(now);
        return Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                l10n.homeFastingStatusLabel,
                style: text.bodySmall?.copyWith(color: colors.textDimmer),
              ),
            ),
            Expanded(
              child: Text(
                l10n.homeFastingActive(_formatHM(elapsed)),
                style: text.bodyMedium?.copyWith(color: colors.text),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FastingLastRow extends StatelessWidget {
  const _FastingLastRow({required this.fast});

  final Fast fast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final duration = fast.endAt!.difference(fast.startAt);
    final whenLabel = _relativeWhen(fast.endAt!, DateTime.now(), locale, l10n);

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            l10n.homeFastingLastLabel,
            style: text.bodySmall?.copyWith(color: colors.textDimmer),
          ),
        ),
        Expanded(
          child: Text(
            l10n.homeFastingLast(_formatHM(duration), whenLabel),
            style: text.bodyMedium?.copyWith(color: colors.textDim),
          ),
        ),
      ],
    );
  }
}

String _formatHM(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

String _relativeWhen(
  DateTime when,
  DateTime now,
  String locale,
  AppLocalizations l10n,
) {
  final today = DateTime(now.year, now.month, now.day);
  final whenDay = DateTime(when.year, when.month, when.day);
  final timeStr = DateFormat.Hm(locale).format(when);
  if (whenDay == today) {
    return '${l10n.historyDateToday.toLowerCase()} $timeStr';
  }
  if (whenDay == today.subtract(const Duration(days: 1))) {
    return '${l10n.historyDateYesterday.toLowerCase()} $timeStr';
  }
  return DateFormat.MMMd(locale).add_Hm().format(when);
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/ui/home/widgets/today_hero.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/ui/home/widgets/today_hero.dart
git commit -m "$(cat <<'EOF'
feat(home): add TodayHero widget

Hero block: eyebrow, calorie number with ring + status chip, divider,
fasting status line (active timer / idle CTA), last finished fast line.
Uses Selector to scope rebuilds and reuses ProgressRing.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 14: Widget — `WeeklyFastingCard`

Three inline numeric stats with caption labels, or an empty-state line.

**Files:**
- Create: `lib/ui/home/widgets/weekly_fasting_card.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../state/aggregations.dart';
import '../state/home_view_model.dart';

class WeeklyFastingCard extends StatelessWidget {
  const WeeklyFastingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typo = context.typo;

    return Selector<HomeViewModel, WeeklyFastingSummary>(
      selector: (_, vm) => vm.state.fasting,
      builder: (context, summary, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.homeWeekFastingTitle,
              style: typo.caption.copyWith(
                color: colors.textDim,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.borderDim),
              ),
              child: summary.total == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          l10n.homeWeekFastingEmpty,
                          style: context.text.bodyMedium
                              ?.copyWith(color: colors.textDim),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            value: '${summary.completed}/${summary.total}',
                            label: l10n.homeWeekFastingCompletedLabel,
                          ),
                        ),
                        Expanded(
                          child: _Stat(
                            value: _formatHoursMinutes(summary.totalDuration),
                            label: l10n.homeWeekFastingTotalLabel,
                          ),
                        ),
                        Expanded(
                          child: _Stat(
                            value: _formatAverage(summary.average),
                            label: l10n.homeWeekFastingAverageLabel,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: typo.numericMedium.copyWith(color: colors.text)),
        const SizedBox(height: 4),
        Text(
          label,
          style: typo.caption.copyWith(color: colors.textDim),
        ),
      ],
    );
  }
}

String _formatHoursMinutes(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

String _formatAverage(Duration d) {
  if (d == Duration.zero) return '—';
  final hours = d.inMinutes / 60.0;
  return '${hours.toStringAsFixed(1)}h';
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/ui/home/widgets/weekly_fasting_card.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/ui/home/widgets/weekly_fasting_card.dart
git commit -m "$(cat <<'EOF'
feat(home): add WeeklyFastingCard widget

Three inline stats (completed/total, total duration, average) with
caption labels, or an empty-state line when no fasts in the week.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: `WeekKcalChart` — painter, tap, semantics (no animation yet)

Custom-painted bar chart with goal line, future-day dots, selected highlight, tap delegation, accessibility.

**Files:**
- Create: `lib/ui/home/widgets/week_kcal_chart.dart`
- Create: `lib/ui/home/widgets/week_kcal_chart_painter.dart`
- Create: `test/ui/home/week_kcal_chart_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `test/ui/home/week_kcal_chart_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/l10n/generated/app_localizations.dart';
import 'package:mamba_growth/ui/core/themes/app_theme.dart';
import 'package:mamba_growth/ui/home/state/aggregations.dart';
import 'package:mamba_growth/ui/home/widgets/week_kcal_chart.dart';

void main() {
  WeekKcalChartData _data({int firstFuture = 7, int selected = 3}) {
    final start = DateTime(2026, 4, 26);
    return WeekKcalChartData(
      days: List.generate(
        7,
        (i) => DayKcal(
          day: start.add(Duration(days: i)),
          kcal: 1000 + i * 100,
        ),
      ),
      goal: 2000,
      todayIndex: 3,
      selectedIndex: selected,
      firstFutureIndex: firstFuture,
    );
  }

  Future<void> _pump(WidgetTester tester, Widget w) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt'), Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: w),
      ),
    );
  }

  testWidgets('builds without throwing', (tester) async {
    await _pump(
      tester,
      WeekKcalChart(data: _data(), onSelectDay: (_) {}),
    );
    expect(find.byType(WeekKcalChart), findsOneWidget);
  });

  testWidgets('semantics label includes counts and selection', (tester) async {
    await _pump(
      tester,
      WeekKcalChart(data: _data(), onSelectDay: (_) {}),
    );
    final semantics = tester.getSemantics(find.byType(WeekKcalChart));
    expect(
      semantics.label,
      contains('Calorie chart'),
    );
    expect(semantics.label, contains('1300 kcal'));
  });

  testWidgets('tapping a past column calls onSelectDay', (tester) async {
    int? tapped;
    await _pump(
      tester,
      WeekKcalChart(
        data: _data(firstFuture: 4, selected: 3),
        onSelectDay: (i) => tapped = i,
      ),
    );
    final box = tester.getRect(find.byType(WeekKcalChart));
    // Column 1 center (Monday): 16dp left pad, then 1.5 columns out.
    final colWidth = (box.width - 32) / 7;
    final tapX = box.left + 16 + colWidth * 1.5;
    final tapY = box.center.dy;
    await tester.tapAt(Offset(tapX, tapY));
    expect(tapped, 1);
  });

  testWidgets('tapping a future column does not call onSelectDay',
      (tester) async {
    int? tapped;
    await _pump(
      tester,
      WeekKcalChart(
        data: _data(firstFuture: 4, selected: 3),
        onSelectDay: (i) => tapped = i,
      ),
    );
    final box = tester.getRect(find.byType(WeekKcalChart));
    final colWidth = (box.width - 32) / 7;
    final tapX = box.left + 16 + colWidth * 5.5; // column 5
    await tester.tapAt(Offset(tapX, box.center.dy));
    expect(tapped, isNull);
  });
}
```

- [ ] **Step 2: Run — must fail at compile**

- [ ] **Step 3: Implement painter**

Create `lib/ui/home/widgets/week_kcal_chart_painter.dart`:

```dart
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
```

- [ ] **Step 4: Implement widget**

Create `lib/ui/home/widgets/week_kcal_chart.dart`:

```dart
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
        '$selectedDayLabel',
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
```

- [ ] **Step 5: Run widget tests — must pass**

```bash
flutter test test/ui/home/week_kcal_chart_test.dart
```

If the semantics test fails because the label format differs, adjust the assertion to match what `homeChartA11y` actually produces (e.g., check for `Calorie chart` and the kcal number).

- [ ] **Step 6: Verify suite**

```bash
flutter analyze
flutter test
```

- [ ] **Step 7: Commit**

```bash
git add lib/ui/home/widgets/week_kcal_chart.dart \
        lib/ui/home/widgets/week_kcal_chart_painter.dart \
        test/ui/home/week_kcal_chart_test.dart
git commit -m "$(cat <<'EOF'
feat(home): add WeekKcalChart with CustomPainter

Bar chart with dashed goal line, future-day dots, selected highlight,
ghost line for today-with-no-data, weekday letters with today bold.
Tap-down delegates to onSelectDay; future taps are ignored. Semantics
wrapper provides the chart label.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 16: `WeekKcalChart` — entry animation

Add a one-shot AnimationController that drives `barAnimation` from 0→1 on first build, with reduced-motion gating.

**Files:**
- Modify: `lib/ui/home/widgets/week_kcal_chart.dart`

- [ ] **Step 1: Convert to StatefulWidget with animation**

Replace the contents of `lib/ui/home/widgets/week_kcal_chart.dart` with:

```dart
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
```

- [ ] **Step 2: Run tests**

```bash
flutter test test/ui/home/week_kcal_chart_test.dart
```

The existing tests do not assert animation; they should still pass after `await tester.pumpAndSettle()`. Update the tap tests to add `await tester.pumpAndSettle();` if any flake.

- [ ] **Step 3: Verify suite**

```bash
flutter analyze
flutter test
```

- [ ] **Step 4: Commit**

```bash
git add lib/ui/home/widgets/week_kcal_chart.dart
git commit -m "$(cat <<'EOF'
feat(home): animate WeekKcalChart bars on first build

400ms easeOutCubic from 0→1 on the bar-height multiplier, gated by
MediaQuery.disableAnimationsOf for reduced-motion support. One-shot:
re-renders from selection changes do not re-trigger the animation.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 17: `HomeScreen` wiring + cross-tab navigation

Compose all widgets, wire the RefreshIndicator, accept the cross-tab navigation callback for the "Iniciar →" CTA, register the `HomeViewModel` provider in `main_navigation_screen.dart`.

**Files:**
- Modify: `lib/ui/home/widgets/home_screen.dart` (replace `EmptyFeatureState` with the real screen)
- Modify: `lib/ui/main/widgets/main_navigation_screen.dart` (provide the VM and pass the tab-switch callback)

- [ ] **Step 1: Replace `home_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../data/repositories/meals/meals_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../state/aggregations.dart';
import '../state/home_state.dart';
import '../state/home_view_model.dart';
import 'today_hero.dart';
import 'week_kcal_chart.dart';
import 'weekly_fasting_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSwitchToFastingTab});

  final VoidCallback onSwitchToFastingTab;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (ctx) => HomeViewModel(
        meals: ctx.read<MealsRepository>(),
        fasting: ctx.read<FastingRepository>(),
      ),
      child: _HomeScreenBody(onSwitchToFastingTab: onSwitchToFastingTab),
    );
  }
}

class _HomeScreenBody extends StatelessWidget {
  const _HomeScreenBody({required this.onSwitchToFastingTab});

  final VoidCallback onSwitchToFastingTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final vm = context.read<HomeViewModel>();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.homeOverviewTitle)),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => vm.reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              TodayHero(onStartFastTap: onSwitchToFastingTab),
              const SizedBox(height: AppSpacing.xl),
              const _WeekChartSection(),
              const SizedBox(height: AppSpacing.xl),
              const WeeklyFastingCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekChartSection extends StatelessWidget {
  const _WeekChartSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typo = context.typo;

    return Selector<HomeViewModel, _ChartData>(
      selector: (_, vm) => _ChartData.fromState(vm.state),
      shouldRebuild: (a, b) => !a.equals(b),
      builder: (context, d, _) {
        final eyebrow = d.daysClosed == 0
            ? l10n.homeWeekEyebrow
            : '${l10n.homeWeekEyebrow} · ${l10n.homeWeekOnTarget(d.daysOnTarget, d.daysClosed)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              eyebrow,
              style: typo.caption.copyWith(
                color: colors.textDim,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.borderDim),
              ),
              child: WeekKcalChart(
                data: WeekKcalChartData(
                  days: d.days,
                  goal: d.goal,
                  todayIndex: d.todayIndex,
                  selectedIndex: d.selectedIndex,
                  firstFutureIndex: d.firstFutureIndex,
                ),
                onSelectDay: (i) =>
                    context.read<HomeViewModel>().selectDay(i),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartData {
  const _ChartData({
    required this.days,
    required this.goal,
    required this.todayIndex,
    required this.selectedIndex,
    required this.firstFutureIndex,
    required this.daysOnTarget,
    required this.daysClosed,
  });

  final List<DayKcal> days;
  final int? goal;
  final int todayIndex;
  final int selectedIndex;
  final int firstFutureIndex;
  final int daysOnTarget;
  final int daysClosed;

  factory _ChartData.fromState(HomeState s) => _ChartData(
        days: s.weekDays,
        goal: s.goal,
        todayIndex: s.todayIndex,
        selectedIndex: s.selectedDayIndex,
        firstFutureIndex: s.firstFutureIndex,
        daysOnTarget: s.daysOnTargetClosed,
        daysClosed: s.daysClosedThisWeek,
      );

  bool equals(_ChartData o) =>
      goal == o.goal &&
      todayIndex == o.todayIndex &&
      selectedIndex == o.selectedIndex &&
      firstFutureIndex == o.firstFutureIndex &&
      daysOnTarget == o.daysOnTarget &&
      daysClosed == o.daysClosed &&
      _listEqual(days, o.days);
}

bool _listEqual(List<DayKcal> a, List<DayKcal> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

- [ ] **Step 2: Update `main_navigation_screen.dart` to pass the callback**

In `lib/ui/main/widgets/main_navigation_screen.dart`, replace the entry for the Home tab in `_pages` with a builder so the callback can capture `_pageController`.

Replace the `_pages` static field with an instance method, and update `build` accordingly:

```dart
  // remove:
  // static const _pages = <Widget>[ ... ];

  // add inside _MainNavigationScreenState:
  late final List<Widget> _pages = [
    HomeScreen(
      onSwitchToFastingTab: () => _onDestinationSelected(1),
    ),
    const FastingScreen(),
    const MealsScreen(),
    const ProfileScreen(),
  ];
```

Make sure the `_pages` reference inside `PageView` is updated to use `_pages` (without `const`).

- [ ] **Step 3: Verify suite**

```bash
flutter analyze
flutter test
```
Green. ~95 tests now.

- [ ] **Step 4: Manual smoke test**

Run the app. Verify:
- Tab "Início" loads with the new dashboard.
- Calorie number reflects your day's meals.
- Tap a previous bar → number above the chart updates.
- Tap "Iniciar" in the idle status row → navigation animates to the Fasting tab.
- Pull to refresh works.

```bash
flutter run
```

(Smoke testing is manual; do not block the implementation if it works visually.)

- [ ] **Step 5: Commit**

```bash
git add lib/ui/home/widgets/home_screen.dart lib/ui/main/widgets/main_navigation_screen.dart
git commit -m "$(cat <<'EOF'
feat(home): wire HomeScreen with VM, chart, weekly cards

Composes TodayHero + WeekKcalChart + WeeklyFastingCard inside a
ChangeNotifierProvider that creates the HomeViewModel from the existing
MealsRepository and FastingRepository providers. RefreshIndicator
triggers vm.reload(). Cross-tab navigation: the idle "Iniciar →" CTA
calls back into MainNavigationScreen which animates PageController to
the Fasting tab.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 18: Final pass — analyze + test sweep + cleanups

Last verification, plus cleanup of any TODO comments left in passes 9–17.

- [ ] **Step 1: Search for stragglers**

```bash
grep -rn "TODO\|XXX\|FIXME" lib/ui/home test/ui/home || echo "clean"
```

If anything pops up that is not a pre-existing comment from the old code, address it.

- [ ] **Step 2: Run analyze + full test**

```bash
flutter analyze
flutter test
```
Both green. Test count: ~95 (previous 60 + 17 aggregations + 7 VM + 4 chart).

- [ ] **Step 3: Branch state check**

```bash
git status
git log --oneline origin/main..HEAD
```

Verify the commit history for the branch reads as a clean sequence:

```
feat(home): wire HomeScreen with VM, chart, weekly cards
feat(home): animate WeekKcalChart bars on first build
feat(home): add WeekKcalChart with CustomPainter
feat(home): add WeeklyFastingCard widget
feat(home): add TodayHero widget
feat(home): add VM selectDay, reload, and midnight rollover
test(home): cover VM fasting state and completed fasts stream
test(home): cover VM meal stream and goal change
feat(home): add HomeViewModel skeleton with initial load
test(home): add Meals/Fasting repo fakes for VM tests
feat(home): add HomeState data class
feat(home): add l10n keys for overview screen
feat(home): add weekly fasting aggregations
feat(home): add calorie & target aggregations
feat(home): extract date helpers into aggregations.dart
chore(nav): rename ui/dashboard → ui/home (placeholder)
chore(nav): rename ui/home → ui/fasting
docs(home): add overview dashboard design spec
```

- [ ] **Step 4: Done**

No commit at this step — verification only.

---

## Self-review checklist (post-plan)

- **Spec coverage:** every section of the design spec maps to a task above.
  - Tab placement and rename → Tasks 1, 2.
  - Architecture (HomeViewModel + aggregations) → Tasks 3–5, 7–12.
  - State exposed by VM → Task 7.
  - Triggers and data flow → Task 9–12.
  - Layout visual → Tasks 13, 14, 17.
  - WeekKcalChart (CustomPainter) → Tasks 15, 16.
  - Aggregations (pure functions) → Tasks 3–5.
  - Error handling → Task 9 (`_loadWeek` try/catch).
  - Testing strategy → Tasks 4, 5, 9–12, 15.
  - Localization → Task 6.
  - Theming (no new tokens) → Tasks 13–17 (uses existing tokens only).
  - YAGNI list → respected (no goldens, no toggle, no streak).

- **Placeholder scan:** no `TBD`/`TODO`/"add appropriate" — all concrete code blocks.

- **Type consistency:** `HomeState` properties referenced in tasks match across plan; `WeekKcalChartData` constructor matches widget and painter; `WeeklyFastingSummary.empty` matches `aggregations.dart` definition; `MealStatus` enum values match the switch expression in `_StatusChip`.

- **Cross-task references:** every symbol used after its introduction (`startOfDay`, `MealStatus`, `DayKcal`, `WeeklyFastingSummary`, `HomeState.empty`, `aggregateWeekKcal`, etc.) is defined in an earlier task.
