# Home (Overview) — Design Spec

**Date:** 2026-04-30
**Status:** Approved (pending implementation plan)
**Owner:** Kaian

## Goal

Replace the empty placeholder of the first tab (`navHome` = "Início") with a calm, scannable **dashboard of the day**. On open the user must understand, in under one second:

1. How many calories they consumed today, and whether that is **on target** vs the daily goal.
2. Their **current fasting status** (active timer or idle) and the most recent finished fast.
3. The **week-to-date evolution** of calories vs goal, and a numeric summary of fasts in the week.

## Non-goals

- Editing meals or fasts from this screen (those flows remain in `MealsScreen` and `FastingScreen`).
- Monthly/yearly history or streaks.
- Push notifications, exports, sharing.
- Cross-device sync UI.

## Tab placement and rename (chore commit, separate from feature)

The current navigation has a confusing mismatch between code and labels: the file `lib/ui/home/home_screen.dart` is the **fasting timer**, while `lib/ui/dashboard/dashboard_screen.dart` is the **empty "Início" placeholder**. Before the feature, we rename:

- `lib/ui/home/`           → `lib/ui/fasting/`
- `lib/ui/dashboard/`      → `lib/ui/home/`  (the empty `dashboard_screen.dart` is deleted; replaced by the new feature)
- `HomeScreen` (fasting timer) → `FastingScreen`
- `HomeViewModel`          → `FastingViewModel`
- `test/ui/home_view_model_test.dart` → `test/ui/fasting_view_model_test.dart`

All imports in `main_navigation_screen.dart` and tests are updated. The chore commit must compile cleanly with `flutter analyze` and `flutter test`. After the rename, `lib/ui/home/` is empty and ready for the feature.

## Architecture

**Pattern:** unified `HomeViewModel` orchestrating both repositories, with all derivation logic extracted into pure functions in `aggregations.dart`. This matches the project's existing pattern (see `MealsViewModel`) and keeps the heavy logic unit-testable without `pumpWidget`.

```
lib/ui/home/
  state/
    home_state.dart           # data classes + enums
    home_view_model.dart      # ChangeNotifier + WidgetsBindingObserver
    aggregations.dart         # pure functions (testable in isolation)
  widgets/
    home_screen.dart          # Scaffold + ListView + RefreshIndicator + Selectors
    today_hero.dart           # number + ProgressRing + status chip + 2 fasting lines
    week_kcal_chart.dart      # public widget; tap handling + Semantics wrapper
    week_kcal_chart_painter.dart  # CustomPainter for bars + goal line + labels
    weekly_fasting_card.dart  # 3 inline numeric stats
test/ui/home/
  aggregations_test.dart
  home_view_model_test.dart
  week_kcal_chart_test.dart   # semantics-only, no goldens
```

`startOfWeekSunday` and `currentWeekDays` are **moved out** of `WeekDaySelector` (where they live as static methods today) and into `aggregations.dart`. The widget then imports from `aggregations.dart`. This consolidates date utilities in one place. Existing tests of `WeekDaySelector` updated accordingly.

## State exposed by the ViewModel

```dart
enum MealStatus { noGoal, underGoal, atGoal, overGoal }

class DayKcal {
  final DateTime day;       // startOfDay
  final int kcal;
}

class WeeklyFastingSummary {
  final int completed;          // fasts that hit target this week
  final int total;              // sessions started in week
  final Duration totalDuration;
  final Duration average;       // totalDuration / days with at least one fast
}

class HomeState {
  final bool isInitialized;
  final DateTime today;          // startOfDay
  final DateTime weekStart;      // startOfWeekSunday(today)

  // Today
  final int todayKcal;
  final int? goal;
  final MealStatus status;

  // Fasting state
  final Fast? activeFast;
  final Fast? lastFinishedFast;  // most recent across all time, may be null

  // Week (calories)
  final List<DayKcal> weekDays;  // length 7, dom→sáb
  final int daysOnTargetClosed;  // numerator of "X de Y na meta"
  final int daysClosedThisWeek;  // denominator (excludes today + future)

  // Week (fasting)
  final WeeklyFastingSummary fasting;

  // UI-only
  final int selectedDayIndex;    // 0..6, defaults to today's index
}
```

The VM also exposes a `ValueListenable<DateTime> nowListenable` that ticks 1Hz **only while `activeFast != null`** (same pattern as the current `HomeViewModel` we are renaming to `FastingViewModel`).

## Triggers and data flow

| Source | When it fires | What the VM does |
|---|---|---|
| `meals.watchMealsForDay(today)` (Stream) | meal add/update/delete | recompute `todayKcal`, replace `weekDays[todayIndex]`, recompute `status` and `daysOnTargetClosed` |
| `meals.goalListenable` | goal changed in Profile | update `goal`, recompute `status` and `daysOnTargetClosed` |
| `fasting` (ChangeNotifier) | `activeFast` or `selectedProtocol` changes | refresh hero "Status" line; start/stop the 1Hz ticker |
| `fasting.watchCompletedFasts()` (Stream) | fast finished | refresh `lastFinishedFast`; reload `getFastsBetween(weekStart, weekEnd)` and recompute `WeeklyFastingSummary` |
| `WidgetsBindingObserver.didChangeAppLifecycleState(resumed)` | app resumes | if `startOfDay(now) != today`: re-init (today, weekStart, all subscriptions, all aggregations) |
| `RefreshIndicator` pull-to-refresh | user pulls | `viewModel.reload()` recomputes everything from current `nowProvider()` |

**Initial load (`_init`):**
1. `today = startOfDay(nowProvider())`, `weekStart = startOfWeekSunday(today)`.
2. Subscribe to `watchMealsForDay(today)` and `watchCompletedFasts()`.
3. Run `getMealsBetween(weekStart, weekEnd)` and `getFastsBetween(weekStart, weekEnd)` in parallel.
4. Mark `isInitialized = true` once both repos report `isInitialized && true` and both Futures resolve.

The week window for calories is **only re-fetched on init, on lifecycle resume, and on pull-to-refresh**. Adding a meal updates only the today bar via the stream — the other six days do not change in the same session.

## Layout (visual reference)

See "Section 2 wireframe" in the brainstorm transcript. Key visual rules:

- **Today eyebrow:** `caption` uppercase, `textDim`, letter-spacing 2.4. Format: `HOJE · QUI 30 ABR` (PT) / `TODAY · THU APR 30` (EN).
- **Calorie number:** `numericDisplay` (56pt mono) + suffix `numericMedium` (18pt mono) `kcal` aligned to baseline. Color `text`.
- **ProgressRing:** 120dp, ring color `accent` if `kcal <= goal`, `accentWarm` if over. If no goal, ring is replaced by `numericDisplay` only (same as `MealsScreen` precedent).
- **Status chip:** colored dot + label.
  - `On target` → `accent` dot, `text` label.
  - `Over by N kcal` → `accentWarm` dot, `text` label.
  - `Set a goal` → `textDimmer` dot, `accent` label (links to `CalorieGoalSheet`).
- **Fasting lines (two stacked rows under the hero):**
  - Row 1 (`Status`): `Em jejum há 14h 12m` if active (timer ticks via `nowListenable`); `Sem jejum agora · Iniciar →` if not. The `Iniciar` action delegates upward via a callback prop on `HomeScreen` so the parent `MainNavigationScreen` can animate its `PageController` to the Fasting tab — same mechanism used by other cross-tab navigations in the app. No new global state needed.
  - Row 2 (`Último`): `16h 04m · ontem 12:30` from `lastFinishedFast`. Hidden if never.
- **Week eyebrow:** `THIS WEEK · 3/5 ON TARGET` (numerator/denominator built from `daysOnTargetClosed`/`daysClosedThisWeek`). If `daysClosedThisWeek == 0` (it's Sunday and the week has just begun), reduce to `THIS WEEK`.
- **Chart:** see Section 3 below.
- **Weekly fasting card:** three inline stats — `5/7` (completed), `92h 06m` (total), `16,3h` (average) — each with caption label below. If `completed == 0`, replace card body with `Nenhum jejum esta semana`.

## `WeekKcalChart` (CustomPainter)

**Public widget API:**
```dart
class WeekKcalChart extends StatelessWidget {
  final WeekKcalChartData data;
  final ValueChanged<int> onSelectDay;
  const WeekKcalChart({required this.data, required this.onSelectDay});
}

class WeekKcalChartData {
  final List<DayKcal> days;        // 7 entries dom→sáb
  final int? goal;                  // null disables goal line
  final int todayIndex;             // 0..6
  final int selectedIndex;          // 0..6 (defaults to today)
  final int firstFutureIndex;       // 0..7; days >= are rendered as a dot
}
```

**Layout (constants in widget body, no magic numbers in painter):**
- Total height 180dp.
- Internal padding: 16dp left/right, 32dp top, 28dp bottom.
- 7 columns evenly distributed; bar width = colWidth × 0.55; bar corner radius 4dp on top edges only.
- Y-scale = `max(maxKcalInWeek, goal ?? 0) × 1.15`.

**Paint passes (in order):**
1. Goal dashed line (1px, 4-4 dash, `borderDim`) + `numericSmall` label `"meta 2.000"` flush right. Skip if `goal == null`.
2. Per column:
   - `i >= firstFutureIndex`: 4dp dot in `borderDim` at base center.
   - else: rounded bar. Color resolution:
     - `i == selectedIndex && days[i].kcal > (goal ?? infinity)` → `accentWarm`.
     - `i == selectedIndex` → `accent`.
     - `i == todayIndex && days[i].kcal == 0` → 1dp ghost line in `borderDim`.
     - otherwise → `surface2`.
3. Floating label above the **selected** bar: `numericMedium` mono, `text`, centered horizontally, baseline 8dp above bar top. Hidden if `selectedIndex >= firstFutureIndex` (cannot select future).
4. Base axis line, 1px `borderDim`.
5. Weekday letter under each column: `bodySmall` 1-letter (D S T Q Q S S in PT / S M T W T F S in EN). `text` + bold for today, `textDim` for others.

**Tap handling (in widget, not painter):**
```dart
onTapDown: (details) {
  final localX = details.localPosition.dx;
  final index = ((localX - leftPad) / colWidth).floor().clamp(0, 6);
  if (index < data.firstFutureIndex) onSelectDay(index);
}
```

**Animation (one-shot, on first build only):**
- 400ms `Curves.easeOutCubic`.
- Bars grow from 0 to final height with 30ms stagger left→right (~600ms total).
- Tracked via `AnimationController`, gated by `MediaQuery.disableAnimationsOf(context)` (skip if reduced-motion).

**Accessibility:**
- `Semantics(label: l10n.homeChartA11y(on, closed, dayLabel, kcal))` wraps the painter.
- Each column has effective tap height ≥44dp (full chart 180dp).

## Aggregations (pure functions)

```dart
DateTime startOfDay(DateTime d);
DateTime startOfWeekSunday(DateTime d);
List<DateTime> currentWeekDays(DateTime d);

List<DayKcal> aggregateWeekKcal({
  required List<Meal> meals,
  required DateTime weekStart,
});

({int onTarget, int closed}) daysOnTarget({
  required List<DayKcal> weekDays,
  required int? goal,
  required DateTime today,
});

MealStatus computeStatus({required int consumed, required int? goal});

WeeklyFastingSummary aggregateWeeklyFasting({
  required List<Fast> fasts,
  required DateTime weekStart,
});

Fast? lastFinishedFast(List<Fast> completedFasts);
```

**Decisions baked into the aggregations:**
- A meal belongs to the day of its `eatenAt` (project precedent).
- A fast belongs to the day of its `endAt` (matches `MealsHistoryScreen` precedent).
- "Day on target" requires `goal != null` and `kcal <= goal`. A day with 0 kcal counts as on target if a goal exists.
- "Days closed this week" excludes today and future days. Sunday is the first day of the week (BR convention), so `daysClosedThisWeek == 0` throughout Sunday until midnight. The eyebrow shrinks to plain `THIS WEEK` in that case.
- `lastFinishedFast` returns the fast with the most recent `endAt`, regardless of date.

## Error handling

- `getMealsBetween` and `getFastsBetween` are wrapped in `try/catch` inside `_loadWeek()`. On error: keep previous values, log to debugPrint, do not show an error UI (YAGNI for v1).
- The streams are project-trusted; if they error, the existing `MealsRepository`/`FastingRepository` already log. The VM swallows errors from listeners to keep the UI from crashing.
- Mutations do not happen on this screen, so no `Result<T>` handling here.

## Testing strategy

**Unit (`aggregations_test.dart`):**
- `aggregateWeekKcal`: 5 days with mixed kcals → correct `weekDays[i].kcal`. Meal at 23:59 belongs to its day, meal at 00:01 belongs to next day.
- `daysOnTarget`: today excluded, future excluded, day with 0 kcal counts as on target if goal != null.
- `computeStatus`: `noGoal`, `underGoal`, `atGoal` (consumed == goal), `overGoal` (consumed == goal+1).
- `aggregateWeeklyFasting`: fast crossing midnight grouped by `endAt` day.
- `lastFinishedFast`: most recent `endAt` wins; null on empty list.

**ViewModel (`home_view_model_test.dart`):**
- Fakes for `MealsRepository` and `FastingRepository` mirroring the existing `_FakeRepo` from `calorie_goal_sheet_test.dart`.
- Adding a meal triggers `notifyListeners` and updates `todayKcal`.
- Setting a goal updates `status` and `daysOnTargetClosed`.
- Ending a fast updates `lastFinishedFast` and reloads the weekly summary.
- `nowProvider` injected; simulating midnight rollover triggers re-init.

**Widget (`week_kcal_chart_test.dart`):**
- Build with synthetic `WeekKcalChartData`. Verify `Semantics.label` contains expected counts and selected day kcal.
- Tap on column 3 → `onSelectDay(3)` is called.
- Tap on column 6 when `firstFutureIndex == 5` → no callback.
- No goldens (fragile across platforms).

## Localization

New keys in `app_en.arb` and `app_pt.arb`:

```
homeOverviewTitle
homeTodayEyebrow            { date }
homeStatusOnTarget
homeStatusOverGoal          { n }
homeStatusNoGoal
homeFastingActive           { duration }
homeFastingIdle
homeFastingIdleAction
homeFastingLast             { duration, when }
homeWeekEyebrow
homeWeekOnTarget            { on, closed }
homeWeekChartGoalLabel      { kcal }
homeWeekFastingTitle
homeWeekFastingCompletedLabel
homeWeekFastingTotalLabel
homeWeekFastingAverageLabel
homeWeekFastingEmpty
homeChartA11y               { on, closed, day, kcal }
```

Relative-time strings (`hoje`, `ontem`, `há Xh`) reuse existing `historyDateToday`/`historyDateYesterday` and a small `_relativeWhen(DateTime, DateTime now)` helper local to the widget (no new locale strings needed beyond the two existing).

## Theming

Uses existing tokens only — **no new tokens**. Specifically:
- `colors.text` / `textDim` / `textDimmer` for hierarchy.
- `colors.accent` / `accentWarm` for ring and selected bar (over goal).
- `colors.surface` / `surface2` / `border` / `borderDim` for surfaces and dashed line.
- `typo.numericDisplay` / `numericLarge` / `numericMedium` / `numericSmall` for numbers.
- `typo.caption` for eyebrows.
- `text.bodyMedium` / `bodySmall` for labels and weekday letters.

## Out-of-scope for v1 (explicit YAGNI list)

- Toggle "This week / Last 7 days".
- Streak counter.
- Tap chart bar opens a day detail screen.
- Long-press to add a quick meal.
- Onboarding-only "first-time" banner.
- Goldens for the chart.
- Error UI for failed week loads.
- Sharing/export.

## Dependencies

No new packages. `package_info_plus` is already added in the previous Profile work but unrelated.

## Open questions

None. All design decisions are closed. Implementation will surface micro-decisions (exact paddings, exact dashed pattern lengths) — those can be adjusted during the implementation cycle without amending this spec.
