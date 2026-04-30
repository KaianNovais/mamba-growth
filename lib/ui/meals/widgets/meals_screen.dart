import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
      // Selector escopa o gate de loading: rebuild apenas quando
      // isInitialized vira true (evita rebuildar a árvore inteira a
      // cada notify do VM).
      body: Selector<MealsViewModel, bool>(
        selector: (_, vm) => vm.isInitialized,
        builder: (context, initialized, _) {
          if (!initialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return const _Body();
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: _ScrollArea()),
        _AddButton(),
      ],
    );
  }
}

class _ScrollArea extends StatelessWidget {
  const _ScrollArea();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: const [
        SliverToBoxAdapter(child: _Hero()),
        _MealsSection(),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      ],
    );
  }
}

@immutable
class _HeroData {
  const _HeroData({required this.total, required this.goal});
  final int total;
  final int? goal;

  @override
  bool operator ==(Object other) =>
      other is _HeroData && other.total == total && other.goal == goal;

  @override
  int get hashCode => Object.hash(total, goal);
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typo = context.typo;
    final ringSize =
        (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 280.0);

    return Selector<MealsViewModel, _HeroData>(
      selector: (_, vm) => _HeroData(total: vm.totalKcal, goal: vm.goal),
      builder: (context, data, _) {
        final hasGoal = data.goal != null;
        final eyebrow = hasGoal
            ? l10n.mealsTodayEyebrowWithGoal(data.goal!)
            : l10n.mealsTodayEyebrowNoGoal;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    ? RepaintBoundary(
                        child: _RingHero(data: data, size: ringSize),
                      )
                    : _NumberHero(total: data.total),
              ),
              if (!hasGoal) ...[
                const SizedBox(height: AppSpacing.lg),
                const _NoGoalHint(),
              ],
              const SizedBox(height: AppSpacing.xl),
              Divider(color: colors.borderDim, height: 1),
            ],
          ),
        );
      },
    );
  }
}

class _MealsSection extends StatelessWidget {
  const _MealsSection();

  @override
  Widget build(BuildContext context) {
    // context.select escuta apenas a referência da lista — rebuild só
    // quando a stream do dia emite um novo snapshot.
    final meals = context.select<MealsViewModel, List<Meal>>((vm) => vm.meals);
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typo = context.typo;

    if (meals.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: EmptyFeatureState(
            icon: Icons.restaurant_outlined,
            title: l10n.mealsEmptyTodayTitle,
            subtitle: l10n.mealsEmptyTodaySubtitle,
          ),
        ),
      );
    }

    final eyebrow = meals.length == 1
        ? l10n.mealsListEyebrowOne
        : l10n.mealsListEyebrowMany(meals.length);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      sliver: SliverList.builder(
        // +1: slot 0 é o eyebrow; demais são as refeições.
        itemCount: meals.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                eyebrow,
                style: typo.caption.copyWith(
                  color: colors.textDim,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
          final meal = meals[i - 1];
          return Padding(
            key: ValueKey(meal.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: MealListItem(
              meal: meal,
              onTap: () => _openEdit(ctx, meal),
              onEdit: () => _openEdit(ctx, meal),
              onDelete: () => _confirmDelete(ctx, meal),
            ),
          );
        },
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        child: SizedBox(
          width: double.infinity,
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
      ),
    );
  }
}

Future<void> _openAdd(BuildContext context) async {
  HapticFeedback.lightImpact();
  final vm = context.read<MealsViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final colors = context.colors;
  await AddMealSheet.show(
    context,
    onSave: (name, calories) async {
      await vm.addMeal.execute((name: name, calories: calories));
      _showSnack(
        messenger,
        colors,
        message: vm.addMeal.completed
            ? l10n.mealAddedSnackbar
            : l10n.mealsErrorGeneric,
        isError: !vm.addMeal.completed,
      );
    },
  );
}

Future<void> _openEdit(BuildContext context, Meal meal) async {
  final vm = context.read<MealsViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final colors = context.colors;
  await AddMealSheet.show(
    context,
    initial: meal,
    onSave: (name, calories) async {
      await vm.updateMeal.execute(
        meal.copyWith(name: name, calories: calories),
      );
      _showSnack(
        messenger,
        colors,
        message: vm.updateMeal.completed
            ? l10n.mealUpdatedSnackbar
            : l10n.mealsErrorGeneric,
        isError: !vm.updateMeal.completed,
      );
    },
  );
}

Future<void> _confirmDelete(BuildContext context, Meal meal) async {
  final vm = context.read<MealsViewModel>();
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
  messenger.hideCurrentSnackBar();
  if (vm.deleteMeal.completed) {
    _showSnack(
      messenger,
      colors,
      message: l10n.mealDeletedSnackbar,
      actionLabel: l10n.mealDeletedSnackbarUndo,
      onAction: () => vm.undoDelete(meal),
    );
  } else {
    _showSnack(
      messenger,
      colors,
      message: l10n.mealsErrorGeneric,
      isError: true,
    );
  }
}

void _showSnack(
  ScaffoldMessengerState messenger,
  AppColors colors, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  bool isError = false,
}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.surface2,
      elevation: 6,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.borderDim),
      ),
      duration: const Duration(milliseconds: 2600),
      // Material 3 mantém SnackBars com action persistentes por padrão;
      // forçamos auto-dismiss para que o "Desfazer" não trave a UI.
      persist: false,
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 20,
            color: isError ? colors.accentWarm : colors.accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: colors.accent,
              onPressed: onAction,
            )
          : null,
    ),
  );
}

class _RingHero extends StatelessWidget {
  const _RingHero({required this.data, required this.size});
  final _HeroData data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final goal = data.goal!;
    final total = data.total;
    final overGoal = total > goal;
    final progress = goal == 0 ? 0.0 : total / goal;
    final ringColor = overGoal ? colors.accentWarm : colors.accent;
    final remaining = goal - total;
    final over = total - goal;
    final label = overGoal
        ? l10n.mealsRingA11yOverGoal(total, over, goal)
        : l10n.mealsRingA11yWithGoal(
            total,
            goal,
            remaining < 0 ? 0 : remaining,
          );

    final String summaryLine;
    final Color summaryColor;
    if (overGoal) {
      summaryLine = l10n.mealsOverGoalLabel(over);
      summaryColor = colors.accentWarm;
    } else if (remaining <= 0) {
      summaryLine = l10n.mealsAtGoalLabel;
      summaryColor = colors.text;
    } else {
      summaryLine = l10n.mealsRemainingLabel(remaining);
      summaryColor = colors.text;
    }

    return Semantics(
      label: label,
      child: ProgressRing(
        progress: progress,
        size: size,
        color: ringColor,
        overflowColor: colors.accentWarm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                total.toString(),
                style: typo.numericLarge.copyWith(color: colors.text),
              ),
              Text(
                l10n.mealsKcalUnit,
                style: typo.caption.copyWith(
                  color: colors.textDim,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                summaryLine,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  color: summaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.mealsOfGoalLabel(goal),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(color: colors.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberHero extends StatelessWidget {
  const _NumberHero({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.mealsRingA11yNoGoal(total),
      child: Column(
        children: [
          Text(
            total.toString(),
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

class _NoGoalHint extends StatelessWidget {
  const _NoGoalHint();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => context.pushNamed(RouteNames.profile),
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
}
