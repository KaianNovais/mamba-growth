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
