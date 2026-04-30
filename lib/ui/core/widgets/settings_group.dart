import 'package:flutter/material.dart';

import '../themes/themes.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        separated.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: AppSpacing.lg + 32 + AppSpacing.md,
            color: colors.borderDim,
          ),
        );
      }
      separated.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text(
              title!.toUpperCase(),
              style: typo.caption.copyWith(
                color: colors.textDim,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.borderDim),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: separated,
          ),
        ),
      ],
    );
  }
}
