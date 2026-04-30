import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/meals/meals_repository.dart';
import '../../../domain/models/meal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/week_day_selector.dart';

class MealsHistoryScreen extends StatefulWidget {
  const MealsHistoryScreen({super.key});

  @override
  State<MealsHistoryScreen> createState() => _MealsHistoryScreenState();
}

class _MealsHistoryScreenState extends State<MealsHistoryScreen> {
  late final DateTime _today;
  late final DateTime _weekStart;
  late final List<DateTime> _weekDays;
  late final Future<Map<DateTime, List<Meal>>> _future;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _weekStart = WeekDaySelector.startOfWeekSunday(_today);
    _weekDays = WeekDaySelector.currentWeekDays(_today);
    _selectedDay = _today;

    final repo = context.read<MealsRepository>();
    final end = _weekStart.add(const Duration(days: 7));
    _future = repo.getMealsBetween(_weekStart, end).then(_groupByDay);
  }

  Map<DateTime, List<Meal>> _groupByDay(List<Meal> meals) {
    final byDay = <DateTime, List<Meal>>{};
    for (final m in meals) {
      final day = DateTime(m.eatenAt.year, m.eatenAt.month, m.eatenAt.day);
      byDay.putIfAbsent(day, () => []).add(m);
    }
    return byDay;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.mealsHistoryTitle)),
      body: SafeArea(
        top: false,
        child: FutureBuilder<Map<DateTime, List<Meal>>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final byDay = snapshot.data!;
            final selectedMeals = byDay[_selectedDay] ?? const <Meal>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                WeekDaySelector(
                  weekDays: _weekDays,
                  today: _today,
                  selectedDay: _selectedDay,
                  onSelect: (day) => setState(() => _selectedDay = day),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (selectedMeals.isEmpty)
                  _EmptyDay(message: l10n.mealsHistoryDayEmpty)
                else
                  _DayCard(day: _selectedDay, meals: selectedMeals),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: colors.textDim),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.meals});

  final DateTime day;
  final List<Meal> meals;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);

    final count = meals.length;
    final countLabel = count == 1
        ? l10n.mealsHistoryMealsCountOne
        : l10n.mealsHistoryMealsCountMany(count);
    final dayLabel = _formatDayLabel(context, day);
    final totalKcal = meals.fold<int>(0, (s, m) => s + m.calories);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${dayLabel.toUpperCase()} · ${countLabel.toUpperCase()}',
            style: typo.caption.copyWith(
              color: colors.textDim,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                totalKcal.toString(),
                style: typo.numericLarge.copyWith(color: colors.text),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.mealsKcalUnit,
                style: typo.caption.copyWith(
                  color: colors.textDim,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.borderDim, height: 1),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < meals.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _MealRow(meal: meals[i]),
          ],
        ],
      ),
    );
  }

  String _formatDayLabel(BuildContext context, DateTime day) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final delta = today.difference(day).inDays;
    return switch (delta) {
      0 => l10n.historyDateToday,
      1 => l10n.historyDateYesterday,
      _ => DateFormat('d MMM', locale).format(day),
    };
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.Hm(locale).format(meal.eatenAt);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.name,
                style: text.bodyLarge?.copyWith(color: colors.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: typo.caption.copyWith(
                  color: colors.textDim,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '${meal.calories} ${l10n.mealsKcalUnit}',
          style: text.bodyMedium?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
