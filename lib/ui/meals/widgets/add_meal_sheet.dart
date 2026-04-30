import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/meal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

class AddMealSheet extends StatefulWidget {
  const AddMealSheet({
    super.key,
    required this.onSave,
    this.initial,
  });

  final Meal? initial;
  final Future<void> Function(String name, int calories) onSave;

  static Future<void> show(
    BuildContext context, {
    Meal? initial,
    required Future<void> Function(String name, int calories) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMealSheet(initial: initial, onSave: onSave),
    );
  }

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
  late final TextEditingController _name;
  late final TextEditingController _cal;
  late final FocusNode _nameFocus;
  late final FocusNode _calFocus;
  late final DateTime _frozenNow;
  String? _nameError;
  String? _calError;
  bool _saving = false;

  static const _maxName = 60;
  static const _maxCal = 9999;

  @override
  void initState() {
    super.initState();
    _frozenNow = widget.initial?.eatenAt ?? DateTime.now();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _cal = TextEditingController(
      text: widget.initial != null ? widget.initial!.calories.toString() : '',
    );
    _nameFocus = FocusNode()..addListener(_onNameBlur);
    _calFocus = FocusNode()..addListener(_onCalBlur);
    _name.addListener(_revalidateOnChange);
    _cal.addListener(_revalidateOnChange);
  }

  @override
  void dispose() {
    _name.dispose();
    _cal.dispose();
    _nameFocus.dispose();
    _calFocus.dispose();
    super.dispose();
  }

  void _onNameBlur() {
    if (!_nameFocus.hasFocus) {
      setState(() => _nameError = _validateName(_name.text));
    }
  }

  void _onCalBlur() {
    if (!_calFocus.hasFocus) {
      setState(() => _calError = _validateCalories(_cal.text));
    }
  }

  void _revalidateOnChange() {
    // Limpa erro à medida que o usuário corrige; não reapresenta sem blur.
    if (_nameError != null && _validateName(_name.text) == null) {
      setState(() => _nameError = null);
    }
    if (_calError != null && _validateCalories(_cal.text) == null) {
      setState(() => _calError = null);
    }
    setState(() {}); // habilita/desabilita Save
  }

  String? _validateName(String s) {
    final l10n = AppLocalizations.of(context);
    final t = s.trim();
    if (t.isEmpty) return l10n.mealValidationNameRequired;
    if (t.length > _maxName) return l10n.mealValidationNameTooLong;
    return null;
  }

  String? _validateCalories(String s) {
    final l10n = AppLocalizations.of(context);
    if (s.trim().isEmpty) return l10n.mealValidationCaloriesRequired;
    final v = int.tryParse(s.trim());
    if (v == null || v < 1 || v > _maxCal) {
      return l10n.mealValidationCaloriesRange;
    }
    return null;
  }

  bool get _isValid =>
      _validateName(_name.text) == null &&
      _validateCalories(_cal.text) == null;

  Future<void> _submit() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      await widget.onSave(_name.text.trim(), int.parse(_cal.text.trim()));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.initial != null;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeStr = DateFormat.Hm(locale).format(_frozenNow);

    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl + (viewInsets > 0 ? 0 : safeBottom),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.borderDim,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textDim,
                      size: 22,
                    ),
                    tooltip: l10n.mealSheetCancel,
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isEdit ? l10n.mealSheetEditTitle : l10n.mealSheetNewTitle,
              style: text.headlineSmall?.copyWith(color: colors.text),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.mealSheetTimeLabel(timeStr),
              style: text.bodyMedium?.copyWith(color: colors.textDim),
            ),
            const SizedBox(height: AppSpacing.xl),
            ExcludeSemantics(child: _Label(text: l10n.mealSheetNameLabel)),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              label: l10n.mealSheetNameLabel,
              textField: true,
              child: TextField(
                controller: _name,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                maxLength: _maxName,
                decoration: InputDecoration(
                  hintText: l10n.mealSheetNameHint,
                  errorText: _nameError,
                  filled: true,
                  fillColor: colors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _calFocus.requestFocus(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ExcludeSemantics(child: _Label(text: l10n.mealSheetCaloriesLabel)),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              label: l10n.mealSheetCaloriesLabel,
              textField: true,
              child: TextField(
                controller: _cal,
                focusNode: _calFocus,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: typo.numericLarge.copyWith(color: colors.text),
                decoration: InputDecoration(
                  suffixText: l10n.mealsKcalUnit,
                  errorText: _calError,
                  filled: true,
                  fillColor: colors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isValid && !_saving ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(colors.bg),
                        ),
                      )
                    : Text(
                        isEdit ? l10n.mealSheetSaveEdit : l10n.mealSheetSave,
                        style: text.labelLarge?.copyWith(
                          color: colors.bg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final txt = context.text;
    return Text(
      text,
      style: txt.labelMedium?.copyWith(color: colors.textDim),
    );
  }
}
