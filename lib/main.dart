import 'package:flutter/material.dart';

import 'ui/core/themes/themes.dart';

void main() {
  runApp(const MambaGrowthApp());
}

class MambaGrowthApp extends StatelessWidget {
  const MambaGrowthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamba Growth',
      theme: AppTheme.dark(),
      home: const _DesignSystemPreview(),
    );
  }
}

class _DesignSystemPreview extends StatelessWidget {
  const _DesignSystemPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Scaffold(
      appBar: AppBar(title: const Text('Design System')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Hierarquia', style: context.text.titleSmall?.copyWith(color: colors.textDim)),
          const SizedBox(height: AppSpacing.sm),
          Text('Mamba Growth', style: context.text.displayMedium),
          Text('Hábitos que viram disciplina',
              style: context.text.bodyLarge?.copyWith(color: colors.textDim)),
          const SizedBox(height: AppSpacing.xl2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.borderDim),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CALORIAS HOJE',
                    style: typo.caption.copyWith(color: colors.textDim)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('1.847', style: typo.numericLarge.copyWith(color: colors.text)),
                    const SizedBox(width: AppSpacing.xs),
                    Text('kcal',
                        style: context.text.bodyMedium?.copyWith(color: colors.textDim)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: 0.74,
                    minHeight: 6,
                    backgroundColor: colors.surface2,
                    valueColor: AlwaysStoppedAnimation(colors.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Registrar refeição'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Cancelar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Buscar alimento',
              hintText: 'Ex: arroz integral',
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Text('Timestamps', style: typo.caption.copyWith(color: colors.textDimmer)),
          const SizedBox(height: AppSpacing.xs),
          Text('Atualizado às 14:32', style: typo.numericSmall.copyWith(color: colors.textDimmer)),
        ],
      ),
    );
  }
}
