import 'package:flutter/material.dart';

import '../themes/themes.dart';

/// Empty state padrão para features ainda sem conteúdo.
/// Mantém a estética sóbria do app: glow sutil, ícone, título e legenda.
class EmptyFeatureState extends StatelessWidget {
  const EmptyFeatureState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.eyebrow,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl2,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlowingIcon(icon: icon),
            const SizedBox(height: AppSpacing.xl),
            if (eyebrow != null) ...[
              Text(
                eyebrow!.toUpperCase(),
                textAlign: TextAlign.center,
                style: typo.caption.copyWith(
                  color: colors.accent,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(
                color: colors.text,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: colors.textDim,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowingIcon extends StatelessWidget {
  const _GlowingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.accent.withValues(alpha: 0.18),
                  colors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 28, color: colors.accent),
          ),
        ],
      ),
    );
  }
}
