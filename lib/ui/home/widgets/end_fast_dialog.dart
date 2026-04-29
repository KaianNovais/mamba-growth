import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/fast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

/// Diálogo de confirmação para encerrar o jejum ativo.
///
/// Resolve `true` quando o usuário confirma; `false` ou `null` ao
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
    final scheme = context.scheme;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final overshot = fast.overshot(now);
    final body = overshot
        ? l10n.homeEndDialogSurpassed(_formatHm(now.difference(fast.plannedEndAt)))
        : l10n.homeEndDialogBody(
            _formatHm(fast.elapsed(now)),
            '${fast.targetHours}h',
          );

    return AlertDialog(
      title: Text(l10n.homeEndDialogTitle),
      content: Text(body, style: text.bodyMedium?.copyWith(color: colors.textDim)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.homeEndDialogCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(true);
          },
          child: Text(l10n.homeEndDialogConfirm),
        ),
      ],
    );
  }
}
