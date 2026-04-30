import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/meals/meals_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

class CalorieGoalSheet extends StatefulWidget {
  const CalorieGoalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<MealsRepository>.value(
        value: context.read<MealsRepository>(),
        child: const CalorieGoalSheet(),
      ),
    );
  }

  @override
  State<CalorieGoalSheet> createState() => _CalorieGoalSheetState();
}

class _CalorieGoalSheetState extends State<CalorieGoalSheet> {
  late final TextEditingController _ctrl;
  String? _error;

  static const _suggestions = [1500, 2000, 2500];
  static const _min = 500;
  static const _max = 9999;

  @override
  void initState() {
    super.initState();
    final initial = context.read<MealsRepository>().currentGoal;
    _ctrl = TextEditingController(text: initial?.toString() ?? '');
    _ctrl.addListener(() {
      if (!mounted) return;
      final clearedError = _error != null && _validate(_ctrl.text) == null;
      setState(() {
        if (clearedError) _error = null;
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _validate(String s) {
    final l10n = AppLocalizations.of(context);
    final v = int.tryParse(s.trim());
    if (v == null || v < _min || v > _max) {
      return l10n.profileGoalValidationRange;
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate(_ctrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    HapticFeedback.lightImpact();
    await context.read<MealsRepository>().setGoal(int.parse(_ctrl.text.trim()));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    HapticFeedback.lightImpact();
    await context.read<MealsRepository>().clearGoal();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final hasGoal = context.watch<MealsRepository>().currentGoal != null;
    final selectedSuggestion = int.tryParse(_ctrl.text.trim());

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.borderDim,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.profileGoalSheetTitle,
                  style: text.headlineSmall?.copyWith(color: colors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.profileGoalSheetSubtitle,
                  style: text.bodyMedium?.copyWith(color: colors.textDim),
                ),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  label: l10n.mealSheetCaloriesLabel,
                  textField: true,
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    style: typo.numericLarge.copyWith(color: colors.text),
                    decoration: InputDecoration(
                      labelText: l10n.mealSheetCaloriesLabel,
                      suffixText: l10n.mealsKcalUnit,
                      errorText: _error,
                      filled: true,
                      fillColor: colors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.profileGoalSheetSuggestionsLabel.toUpperCase(),
                  style: typo.caption.copyWith(
                    color: colors.textDim,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final s in _suggestions)
                      ChoiceChip(
                        label: Text('$s kcal'),
                        selected: selectedSuggestion == s,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          _ctrl.text = s.toString();
                          _ctrl.selection = TextSelection.collapsed(
                            offset: _ctrl.text.length,
                          );
                          setState(() {});
                        },
                        showCheckmark: false,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Text(
                      l10n.profileGoalSheetSave,
                      style: text.labelLarge?.copyWith(
                        color: colors.bg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (hasGoal) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: _remove,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.danger,
                      ),
                      child: Text(
                        l10n.profileGoalSheetRemove,
                        style: text.labelLarge?.copyWith(
                          color: colors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
