import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/domain/models/fast.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/ui/home/state/aggregations.dart';
import 'package:mamba_growth/ui/home/state/home_view_model.dart';

import '_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    meals.setTodayMeals([
      Meal(id: 1, name: 'a', calories: 2100, eatenAt: now),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.todayKcal, 2100);
    expect(vm.state.status, MealStatus.overGoal);
    expect(vm.state.weekDays[vm.state.todayIndex].kcal, 2100);
    vm.dispose();
  });

  test('changing goal recomputes status', () async {
    final meals = FakeMealsRepository();
    final fasting = FakeFastingRepository();
    final now = DateTime(2026, 4, 30, 9);

    final vm = HomeViewModel(
      meals: meals,
      fasting: fasting,
      nowProvider: () => now,
    );
    await Future<void>.delayed(Duration.zero);
    expect(vm.state.status, MealStatus.noGoal);

    await meals.setGoal(2000);
    await Future<void>.delayed(Duration.zero);
    expect(vm.state.goal, 2000);
    expect(vm.state.status, MealStatus.underGoal);
    vm.dispose();
  });

  test('completed fasts stream updates lastFinishedFast and summary',
      () async {
    final meals = FakeMealsRepository();
    final fasting = FakeFastingRepository();
    final vm = HomeViewModel(
      meals: meals,
      fasting: fasting,
      nowProvider: () => DateTime(2026, 4, 30, 9),
    );
    await Future<void>.delayed(Duration.zero);

    final older = Fast(
      id: 1,
      startAt: DateTime(2026, 4, 26, 20),
      endAt: DateTime(2026, 4, 27, 12),
      targetHours: 16,
      eatingHours: 8,
      completed: true,
    );
    final newer = Fast(
      id: 2,
      startAt: DateTime(2026, 4, 28, 20),
      endAt: DateTime(2026, 4, 29, 12),
      targetHours: 16,
      eatingHours: 8,
      completed: true,
    );
    fasting.setCompleted([older, newer]);
    await Future<void>.delayed(Duration.zero);

    expect(vm.state.lastFinishedFast, newer);
    expect(vm.state.fasting.completed, 2);
    expect(vm.state.fasting.totalDuration, const Duration(hours: 32));
    vm.dispose();
  });

  test('selectDay updates index and ignores out-of-range values', () async {
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
    vm.selectDay(7);
    expect(vm.state.selectedDayIndex, 2);
    vm.selectDay(-1);
    expect(vm.state.selectedDayIndex, 2);
    vm.dispose();
  });

  test('reload re-fetches week aggregations and lifecycle handles new day',
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

    now = DateTime(2026, 5, 3, 0, 1);
    vm.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(vm.state.today, DateTime(2026, 5, 3));
    expect(vm.state.weekStart, DateTime(2026, 5, 3));
    vm.dispose();
  });
}
