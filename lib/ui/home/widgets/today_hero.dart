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
    final colors = context.colors;
    final typo = context.typo;
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
        final l10n = AppLocalizations.of(context);
        final dateLabel = DateFormat('EEE d MMM', locale)
            .format(state.today)
            .toUpperCase();
        final progress = (state.goal == null || state.goal == 0)
            ? 0.0
            : (state.todayKcal / state.goal!);
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
                    ProgressRing(
                      progress: progress,
                      size: 96,
                      color: ringColor,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _StatusChip(
                status: state.status,
                goal: state.goal,
                consumed: state.todayKcal,
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(height: 1, color: colors.borderDim),
              const SizedBox(height: AppSpacing.lg),
              _FastingStatusRow(
                state: state,
                onStartFastTap: onStartFastTap,
              ),
              if (state.lastFinishedFast != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _FastingLastRow(fast: state.lastFinishedFast!),
              ],
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
        final isCompleted = activeFast.overshot(now);
        final message = isCompleted
            ? l10n.homeFastingCompleted(_formatHM(elapsed))
            : l10n.homeFastingActive(_formatHM(elapsed));
        final messageColor = isCompleted ? colors.accent : colors.text;
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
                message,
                style: text.bodyMedium?.copyWith(color: messageColor),
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
