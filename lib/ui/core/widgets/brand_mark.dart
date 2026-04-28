import 'package:flutter/material.dart';

import '../themes/themes.dart';

/// Brand mark padronizado: dot luminoso + nome em uppercase.
/// Usado no onboarding e no splash.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.accent,
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label.toUpperCase(),
          style: typo.caption.copyWith(
            color: colors.textDim,
            letterSpacing: 3.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
