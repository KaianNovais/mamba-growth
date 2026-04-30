import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/meal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

class MealListItem extends StatelessWidget {
  const MealListItem({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Meal meal;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeStr = DateFormat.Hm(locale).format(meal.eatenAt);

    return Semantics(
      button: true,
      label: l10n.mealItemA11y(meal.name, meal.calories, timeStr),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
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
                        meal.name,
                        style: text.titleMedium?.copyWith(color: colors.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${meal.calories} ${l10n.mealsKcalUnit}',
                        style: typo.numericMedium.copyWith(color: colors.text),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  timeStr,
                  style: typo.numericSmall.copyWith(color: colors.textDim),
                ),
                const SizedBox(width: AppSpacing.xs),
                _MoreButton(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<_MealAction>(
      icon: Icon(Icons.more_vert_rounded, color: colors.textDim, size: 20),
      tooltip: '',
      color: colors.surface2,
      onSelected: (action) {
        switch (action) {
          case _MealAction.edit:
            onEdit();
          case _MealAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MealAction.edit,
          child: Text(
            l10n.mealItemMenuEdit,
            style: text.bodyMedium?.copyWith(color: colors.text),
          ),
        ),
        PopupMenuItem(
          value: _MealAction.delete,
          child: Text(
            l10n.mealItemMenuDelete,
            style: text.bodyMedium?.copyWith(color: const Color(0xFFE76D6D)),
          ),
        ),
      ],
    );
  }
}

enum _MealAction { edit, delete }
