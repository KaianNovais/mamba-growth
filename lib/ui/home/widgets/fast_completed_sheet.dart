import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

/// Celebração modal exibida quando o usuário encerra um jejum que
/// bateu a meta. Confetti dispara da quina superior; respeita
/// `MediaQuery.disableAnimations` (reduced-motion) — nesse caso só
/// mostra o card sem partículas.
class FastCompletedSheet extends StatefulWidget {
  const FastCompletedSheet._({required this.duration});

  final Duration duration;

  static Future<void> show(
    BuildContext context, {
    required Duration duration,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fast completed',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, _, _) => FastCompletedSheet._(duration: duration),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<FastCompletedSheet> createState() => _FastCompletedSheetState();
}

class _FastCompletedSheetState extends State<FastCompletedSheet> {
  late final ConfettiController _confetti;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    HapticFeedback.heavyImpact();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl2,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colors.accent.withValues(alpha: 0.22),
                            colors.accent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.surface2,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: colors.accent,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        l10n.homeFastCompletedTitle,
                        textAlign: TextAlign.center,
                        style: text.headlineSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        _formatDuration(widget.duration),
                        textAlign: TextAlign.center,
                        style: typo.numericLarge.copyWith(color: colors.accent),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: Text(
                        l10n.homeFastCompletedBody(
                          _formatDuration(widget.duration),
                        ),
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: colors.textDim),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: colors.bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: Text(
                          l10n.homeFastCompletedDismiss,
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
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: math.pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.06,
            numberOfParticles: 24,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.25,
            shouldLoop: false,
            colors: [
              colors.accent,
              colors.accentWarm,
              colors.text,
              colors.accent.withValues(alpha: 0.7),
            ],
          ),
        ),
      ],
    );
  }
}
