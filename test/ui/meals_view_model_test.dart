import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/meals/meals_repository.dart';
import 'package:mamba_growth/domain/models/meal.dart';
import 'package:mamba_growth/ui/meals/view_models/meals_view_model.dart';
import 'package:mamba_growth/utils/result.dart';

/// Fake espelha o contrato do MealsRepositoryLocal real:
/// - `watchMealsForDay` yield-a o snapshot atual e depois forwarda
///   o broadcast controller (stream "ao vivo", não completa após
///   o primeiro yield).
/// - mutadores de refeição emitem via controller (NÃO notifyListeners).
/// - mutadores de meta chamam notifyListeners.
class _FakeMealsRepository extends ChangeNotifier implements MealsRepository {
  final bool _isInitialized = true;
  final ValueNotifier<int?> _goal = ValueNotifier<int?>(null);
  final List<Meal> _meals = [];
  final StreamController<List<Meal>> _ctrl =
      StreamController<List<Meal>>.broadcast();
  int _nextId = 1;

  @override
  bool get isInitialized => _isInitialized;

  @override
  ValueListenable<int?> get goalListenable => _goal;

  @override
  int? get currentGoal => _goal.value;

  @override
  Stream<List<Meal>> watchMealsForDay(DateTime day) async* {
    yield List.unmodifiable(_meals);
    yield* _ctrl.stream;
  }

  @override
  Future<List<Meal>> getMealsBetween(DateTime start, DateTime end) async {
    return _meals
        .where((m) =>
            !m.eatenAt.isBefore(start) && m.eatenAt.isBefore(end))
        .toList();
  }

  void _emit() {
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(_meals));
  }

  @override
  Future<Result<Meal>> addMeal({
    required String name,
    required int calories,
  }) async {
    final meal = Meal(
      id: _nextId++,
      name: name,
      calories: calories,
      eatenAt: DateTime.now(),
    );
    _meals.insert(0, meal);
    _emit();
    return Result.ok(meal);
  }

  @override
  Future<Result<Meal>> updateMeal(Meal meal) async {
    final i = _meals.indexWhere((m) => m.id == meal.id);
    if (i == -1) {
      return const Result.error(MealsException('not found'));
    }
    _meals[i] = meal;
    _emit();
    return Result.ok(meal);
  }

  @override
  Future<Result<void>> deleteMeal(int id) async {
    _meals.removeWhere((m) => m.id == id);
    _emit();
    return const Result.ok(null);
  }

  @override
  Future<Result<Meal>> reinsertMeal(Meal meal) async {
    final restored = meal.copyWith(id: _nextId++);
    _meals.insert(0, restored);
    _emit();
    return Result.ok(restored);
  }

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
    _ctrl.close();
    _goal.dispose();
    super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MealsViewModel', () {
    test('expõe meta e refeições, calcula totalKcal', () async {
      final repo = _FakeMealsRepository();
      final vm = MealsViewModel(repository: repo);
      addTearDown(vm.dispose);
      await Future.delayed(Duration.zero);

      expect(vm.totalKcal, 0);
      expect(vm.goal, isNull);
      expect(vm.overGoal, false);

      await repo.addMeal(name: 'A', calories: 300);
      await repo.addMeal(name: 'B', calories: 400);
      await Future.delayed(Duration.zero);
      expect(vm.totalKcal, 700);
    });

    test('progress = total/goal e overGoal quando excede', () async {
      final repo = _FakeMealsRepository();
      await repo.setGoal(1000);
      final vm = MealsViewModel(repository: repo);
      addTearDown(vm.dispose);
      await Future.delayed(Duration.zero);

      await repo.addMeal(name: 'A', calories: 600);
      await Future.delayed(Duration.zero);
      expect(vm.progress, closeTo(0.6, 1e-6));
      expect(vm.overGoal, false);

      await repo.addMeal(name: 'B', calories: 600);
      await Future.delayed(Duration.zero);
      expect(vm.progress, closeTo(1.2, 1e-6));
      expect(vm.overGoal, true);
    });

    test('addMeal Command roda', () async {
      final repo = _FakeMealsRepository();
      final vm = MealsViewModel(repository: repo);
      addTearDown(vm.dispose);
      await Future.delayed(Duration.zero);

      await vm.addMeal.execute((name: 'Café', calories: 380));
      expect(vm.addMeal.completed, true);
    });

    test('deleteMeal Command + undoDelete restaura', () async {
      final repo = _FakeMealsRepository();
      final vm = MealsViewModel(repository: repo);
      addTearDown(vm.dispose);
      await Future.delayed(Duration.zero);

      final added = await repo.addMeal(name: 'X', calories: 100);
      final meal = (added as Ok<Meal>).value;
      await Future.delayed(Duration.zero);
      expect(vm.meals.length, 1);

      await vm.deleteMeal.execute(meal);
      await Future.delayed(Duration.zero);
      expect(vm.meals.length, 0);

      await vm.undoDelete(meal);
      await Future.delayed(Duration.zero);
      expect(vm.meals.length, 1);
    });
  });
}
