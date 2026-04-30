import 'package:flutter_test/flutter_test.dart';
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
}
