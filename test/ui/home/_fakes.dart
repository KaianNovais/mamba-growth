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
  Future<Result<Meal>> updateMeal(Meal meal) async => Result.ok(meal);

  @override
  Future<Result<void>> deleteMeal(int id) async => const Result.ok(null);

  @override
  Future<Result<Meal>> reinsertMeal(Meal meal) async => Result.ok(meal);

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
  Future<void> setProtocol(FastingProtocol protocol) async {
    _protocol = protocol;
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
