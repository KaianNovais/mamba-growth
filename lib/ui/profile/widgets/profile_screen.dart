import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/meals/meals_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../history/widgets/history_screen.dart';
import '../../meals_history/widgets/meals_history_screen.dart';
import 'calorie_goal_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final repo = context.read<AuthRepository>();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                children: const [
                  _CalorieGoalSection(),
                  SizedBox(height: AppSpacing.xl),
                  _HistorySection(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl2,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => repo.signOut(),
                  child: Text(l10n.profileSignOut),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.profileHistorySectionEyebrow,
          style: typo.caption.copyWith(
            color: colors.textDim,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _NavTile(
          title: l10n.profileHistoryRowTitle,
          subtitle: l10n.profileHistoryRowSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const HistoryScreen(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _NavTile(
          title: l10n.profileMealsHistoryRowTitle,
          subtitle: l10n.profileMealsHistoryRowSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MealsHistoryScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderDim),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(color: colors.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                          text.bodyMedium?.copyWith(color: colors.textDim),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalorieGoalSection extends StatelessWidget {
  const _CalorieGoalSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final goal = context.watch<MealsRepository>().currentGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.profileGoalSectionEyebrow,
          style: typo.caption.copyWith(
            color: colors.textDim,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => CalorieGoalSheet.show(context),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.borderDim),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileGoalCardTitle,
                          style:
                              text.titleMedium?.copyWith(color: colors.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal != null
                              ? l10n.profileGoalCardValue(goal)
                              : l10n.profileGoalCardEmptyValue,
                          style: text.bodyMedium
                              ?.copyWith(color: colors.textDim),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    goal != null
                        ? l10n.profileGoalCardActionEdit
                        : l10n.profileGoalCardActionDefine,
                    style: text.labelMedium?.copyWith(color: colors.accent),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: colors.textDim),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
