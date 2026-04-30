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
    final newWeekStart = startOfWeekSunday(now);
    _state = _state.copyWith(
      today: newToday,
      weekStart: newWeekStart,
      selectedDayIndex: newToday.difference(newWeekStart).inDays,
    );
    _subscribeToday(newToday);
    _loadWeek().then((_) => notifyListeners());
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
