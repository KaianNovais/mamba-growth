import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../domain/models/fasting_protocol.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

class ProtocolBottomSheet extends StatelessWidget {
  const ProtocolBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      builder: (sheetContext) {
        return ChangeNotifierProvider<FastingRepository>.value(
          value: context.read<FastingRepository>(),
          child: const ProtocolBottomSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const _SheetContent();
}

class _SheetContent extends StatefulWidget {
  const _SheetContent();

  @override
  State<_SheetContent> createState() => _SheetContentState();
}

class _SheetContentState extends State<_SheetContent> {
  late FastingProtocol _selected;
  late int _customFasting;

  @override
  void initState() {
    super.initState();
    final repo = context.read<FastingRepository>();
    _selected = repo.selectedProtocol;
    _customFasting = repo.selectedProtocol.isCustom
        ? repo.selectedProtocol.fastingHours
        : 20;
  }

  bool get _isCustomSelected => _selected.isCustom;

  void _selectPreset(FastingProtocol p) {
    HapticFeedback.selectionClick();
    setState(() => _selected = p);
  }

  void _selectCustom() {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = FastingProtocol.custom(
        fastingHours: _customFasting,
        eatingHours: 24 - _customFasting,
      );
    });
  }

  void _onCustomChanged(double v) {
    final hours = v.round().clamp(1, 23);
    setState(() {
      _customFasting = hours;
      if (_isCustomSelected) {
        _selected = FastingProtocol.custom(
          fastingHours: hours,
          eatingHours: 24 - hours,
        );
      }
    });
  }

  Future<void> _confirm() async {
    HapticFeedback.lightImpact();
    await context.read<FastingRepository>().setProtocol(_selected);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final systemGestureInset = MediaQuery.viewPaddingOf(context).bottom;
    final initial = context.read<FastingRepository>().selectedProtocol;
    final changed = _selected != initial;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets + systemGestureInset + AppSpacing.md),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.homeProtocolSheetTitle,
                style: text.headlineSmall?.copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.homeProtocolSheetSubtitle,
                style: text.bodyMedium?.copyWith(color: colors.textDim),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  for (var i = 0; i < FastingProtocol.presets.length; i++) ...[
                    Expanded(
                      child: _ProtocolCard(
                        protocol: FastingProtocol.presets[i],
                        label: switch (FastingProtocol.presets[i].id) {
                          '12:12' => l10n.homeProtocolBeginner,
                          '16:8' => l10n.homeProtocolPopular,
                          '18:6' => l10n.homeProtocolAdvanced,
                          _ => '',
                        },
                        selected: _selected.id == FastingProtocol.presets[i].id,
                        onTap: () => _selectPreset(FastingProtocol.presets[i]),
                      ),
                    ),
                    if (i < FastingProtocol.presets.length - 1)
                      const SizedBox(width: AppSpacing.md),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _CustomCard(
                fastingHours: _customFasting,
                eatingHours: 24 - _customFasting,
                selected: _isCustomSelected,
                onTap: _selectCustom,
                onSliderChanged: _onCustomChanged,
                customLabel: l10n.homeProtocolCustom,
                liveLabel: l10n.homeProtocolCustomLabel(
                  _customFasting,
                  24 - _customFasting,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: changed ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.bg,
                    disabledBackgroundColor:
                        colors.accent.withValues(alpha: 0.4),
                    disabledForegroundColor:
                        colors.bg.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    l10n.homeProtocolConfirm,
                    style: text.labelLarge?.copyWith(
                      color: colors.bg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({
    required this.protocol,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final FastingProtocol protocol;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final borderColor = selected ? colors.accent : colors.border;
    final bgColor = selected
        ? colors.accent.withValues(alpha: 0.08)
        : colors.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text(
              '${protocol.fastingHours} : ${protocol.eatingHours}',
              style: typo.numericLarge.copyWith(
                color: selected ? colors.accent : colors.text,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: typo.caption.copyWith(
                color: selected ? colors.accent : colors.textDim,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomCard extends StatelessWidget {
  const _CustomCard({
    required this.fastingHours,
    required this.eatingHours,
    required this.selected,
    required this.onTap,
    required this.onSliderChanged,
    required this.customLabel,
    required this.liveLabel,
  });

  final int fastingHours;
  final int eatingHours;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<double> onSliderChanged;
  final String customLabel;
  final String liveLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final borderColor = selected ? colors.accent : colors.border;
    final bgColor = selected
        ? colors.accent.withValues(alpha: 0.08)
        : colors.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customLabel,
                  style: text.titleMedium?.copyWith(
                    color: selected ? colors.accent : colors.text,
                  ),
                ),
                Text(
                  liveLabel,
                  style: typo.numericSmall.copyWith(
                    color: selected ? colors.accent : colors.textDim,
                  ),
                ),
              ],
            ),
            Slider(
              min: 1,
              max: 23,
              divisions: 22,
              value: fastingHours.toDouble(),
              activeColor: colors.accent,
              inactiveColor: colors.borderDim,
              onChanged: onSliderChanged,
            ),
          ],
        ),
      ),
    );
  }
}
