import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../state/aggregations.dart';
import '../state/home_view_model.dart';

class WeeklyFastingCard extends StatelessWidget {
  const WeeklyFastingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typo = context.typo;

    return Selector<HomeViewModel, WeeklyFastingSummary>(
      selector: (_, vm) => vm.state.fasting,
      builder: (context, summary, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.homeWeekFastingTitle,
              style: typo.caption.copyWith(
                color: colors.textDim,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.borderDim),
              ),
              child: summary.total == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          l10n.homeWeekFastingEmpty,
                          style: context.text.bodyMedium
                              ?.copyWith(color: colors.textDim),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            value: '${summary.completed}/${summary.total}',
                            label: l10n.homeWeekFastingCompletedLabel,
                          ),
                        ),
                        Expanded(
                          child: _Stat(
                            value: _formatHoursMinutes(summary.totalDuration),
                            label: l10n.homeWeekFastingTotalLabel,
                          ),
                        ),
                        Expanded(
                          child: _Stat(
                            value: _formatAverage(summary.average),
                            label: l10n.homeWeekFastingAverageLabel,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: typo.numericMedium.copyWith(color: colors.text)),
        const SizedBox(height: 4),
        Text(
          label,
          style: typo.caption.copyWith(color: colors.textDim),
        ),
      ],
    );
  }
}

String _formatHoursMinutes(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

String _formatAverage(Duration d) {
  if (d == Duration.zero) return '—';
  final hours = d.inMinutes / 60.0;
  return '${hours.toStringAsFixed(1)}h';
}
