import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/meals/meals_repository.dart';
import '../../../domain/models/meal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';
import '../../core/widgets/progress_ring.dart';
import '../view_models/meals_view_model.dart';
import 'add_meal_sheet.dart';
import 'meal_list_item.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MealsViewModel>(
      create: (ctx) => MealsViewModel(repository: ctx.read<MealsRepository>()),
      child: const _MealsView(),
    );
  }
}

class _MealsView extends StatelessWidget {
  const _MealsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.navMeals)),
      body: SafeArea(
        top: false,
        child: Consumer<MealsViewModel>(
          builder: (context, vm, _) {
            if (!vm.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return _Body(vm: vm);
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vm});
  final MealsViewModel vm;

  Future<void> _openAdd(BuildContext context) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await AddMealSheet.show(
      context,
      onSave: (name, calories) async {
        await vm.addMeal.execute((name: name, calories: calories));
        if (vm.addMeal.completed) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.mealAddedSnackbar)),
          );
        }
      },
    );
  }

  Future<void> _openEdit(BuildContext context, Meal meal) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await AddMealSheet.show(
      context,
      initial: meal,
      onSave: (name, calories) async {
        await vm.updateMeal.execute(
          meal.copyWith(name: name, calories: calories),
        );
        if (vm.updateMeal.completed) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.mealAddedSnackbar)),
          );
        }
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Meal meal) async {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(l10n.mealDeleteDialogTitle),
        content: Text(l10n.mealDeleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.mealDeleteDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.mealDeleteDialogConfirm,
              style: const TextStyle(color: Color(0xFFE76D6D)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await vm.deleteMeal.execute(meal);
    if (vm.deleteMeal.completed) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.mealDeletedSnackbar),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: l10n.mealDeletedSnackbarUndo,
              onPressed: () => vm.undoDelete(meal),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;

    final hasGoal = vm.goal != null;
    final eyebrow = hasGoal
        ? l10n.mealsTodayEyebrowWithGoal(vm.goal!)
        : l10n.mealsTodayEyebrowNoGoal;
    final ringSize =
        (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 280.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            eyebrow.toUpperCase(),
            textAlign: TextAlign.center,
            style: typo.caption.copyWith(
              color: colors.textDim,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: hasGoal
                ? _RingHero(vm: vm, size: ringSize)
                : _NumberHero(vm: vm),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Subtitle(vm: vm),
          const SizedBox(height: AppSpacing.xl),
          Divider(color: colors.borderDim, height: 1),
          const SizedBox(height: AppSpacing.lg),
          if (vm.meals.isEmpty)
            EmptyFeatureState(
              icon: Icons.restaurant_outlined,
              title: l10n.mealsEmptyTodayTitle,
              subtitle: l10n.mealsEmptyTodaySubtitle,
            )
          else ...[
            Text(
              vm.meals.length == 1
                  ? l10n.mealsListEyebrowOne
                  : l10n.mealsListEyebrowMany(vm.meals.length),
              style: typo.caption.copyWith(
                color: colors.textDim,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final meal in vm.meals) ...[
              MealListItem(
                meal: meal,
                onTap: () => _openEdit(context, meal),
                onEdit: () => _openEdit(context, meal),
                onDelete: () => _confirmDelete(context, meal),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _openAdd(context),
              icon: Icon(Icons.add_rounded, color: colors.bg),
              label: Text(
                l10n.mealsAddCta,
                style: text.labelLarge?.copyWith(
                  color: colors.bg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _RingHero extends StatelessWidget {
  const _RingHero({required this.vm, required this.size});
  final MealsViewModel vm;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final ringColor = vm.overGoal ? colors.accentWarm : colors.accent;
    final remaining = (vm.goal ?? 0) - vm.totalKcal;
    final over = vm.totalKcal - (vm.goal ?? 0);
    final label = vm.overGoal
        ? l10n.mealsRingA11yOverGoal(vm.totalKcal, over, vm.goal!)
        : l10n.mealsRingA11yWithGoal(
            vm.totalKcal,
            vm.goal!,
            remaining < 0 ? 0 : remaining,
          );

    return Semantics(
      label: label,
      child: ProgressRing(
        progress: vm.progress,
        size: size,
        color: ringColor,
        overflowColor: colors.accentWarm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.totalKcal.toString(),
              style: typo.numericLarge.copyWith(color: colors.text),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.mealsKcalUnit,
              style: typo.caption.copyWith(
                color: colors.textDim,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberHero extends StatelessWidget {
  const _NumberHero({required this.vm});
  final MealsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.mealsRingA11yNoGoal(vm.totalKcal),
      child: Column(
        children: [
          Text(
            vm.totalKcal.toString(),
            style: typo.numericDisplay.copyWith(color: colors.text),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.mealsKcalUnit,
            style: typo.caption.copyWith(
              color: colors.textDim,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.vm});
  final MealsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);

    if (vm.goal == null) {
      return InkWell(
        onTap: () => Navigator.of(context).pushNamed(Routes.profile),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            l10n.mealsNoGoalHint,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: colors.textDim),
          ),
        ),
      );
    }

    if (vm.overGoal) {
      final over = vm.totalKcal - vm.goal!;
      return Column(
        children: [
          Text(
            l10n.mealsOverGoalLabel(over),
            style: text.bodyLarge?.copyWith(
              color: colors.accentWarm,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.mealsOfGoalLabel(vm.goal!),
            style: text.bodyMedium?.copyWith(color: colors.textDim),
          ),
        ],
      );
    }

    final remaining = vm.goal! - vm.totalKcal;
    return Column(
      children: [
        Text(
          remaining > 0
              ? l10n.mealsRemainingLabel(remaining)
              : l10n.mealsAtGoalLabel,
          style: text.bodyLarge?.copyWith(color: colors.text),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.mealsOfGoalLabel(vm.goal!),
          style: text.bodyMedium?.copyWith(color: colors.textDim),
        ),
      ],
    );
  }
}
