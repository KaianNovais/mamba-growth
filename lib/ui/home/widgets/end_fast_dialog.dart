import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/fast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

/// Diálogo de "freio" — só aparece quando o usuário tenta encerrar
/// **antes** de bater a meta. A hierarquia visual é deliberadamente
/// invertida: a CTA primária ("Continuar jejuando") usa o accent
/// dourado em destaque, enquanto "Encerrar mesmo assim" é um texto
/// discreto em vermelho — fricção psicológica contra desistência.
///
/// Resolve `true` quando o usuário confirma encerrar; `false` ao
/// cancelar (toque fora também cancela).
class EndFastDialog extends StatelessWidget {
  const EndFastDialog._({required this.fast, required this.now});

  final Fast fast;
  final DateTime now;

  static Future<bool> show(
    BuildContext context, {
    required Fast fast,
    required DateTime now,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EndFastDialog._(fast: fast, now: now),
    );
    return result ?? false;
  }

  String _formatHm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final progress = fast.progress(now);
    final percent = (progress * 100).floor();
    final remaining = fast.remaining(now);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.local_fire_department_rounded,
                color: colors.accent,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.homeEndDialogTitle,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.homeEndDialogProgress(percent, _formatHm(remaining)),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.textDim),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: colors.surface2,
                valueColor: AlwaysStoppedAnimation(colors.accent),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(false);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(
                  l10n.homeEndDialogStayCta,
                  style: text.labelLarge?.copyWith(
                    color: colors.bg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE76D6D),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
              ),
              child: Text(
                l10n.homeEndDialogQuitCta,
                style: text.labelLarge?.copyWith(
                  color: const Color(0xFFE76D6D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
