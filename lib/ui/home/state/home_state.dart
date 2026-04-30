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
