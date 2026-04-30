import 'package:flutter/material.dart';

import '../themes/themes.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.onTap,
    this.destructive = false,
    this.showChevron = true,
    this.semanticsLabel,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final titleColor = destructive ? colors.danger : colors.text;
    final iconBgColor =
        destructive ? colors.danger.withValues(alpha: 0.12) : colors.surface2;
    final iconColor = destructive ? colors.danger : colors.textDim;

    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: icon != null
                ? Icon(icon, size: 18, color: iconColor)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: text.titleMedium?.copyWith(color: titleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        text.bodyMedium?.copyWith(color: colors.textDim),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailingText != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              trailingText!,
              style: text.bodyMedium?.copyWith(color: colors.textDim),
            ),
          ],
          if (showChevron && onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textDimmer,
              size: 22,
            ),
          ],
        ],
      ),
    );

    final tile = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: body,
              ),
            )
          : body,
    );

    return Semantics(
      button: onTap != null,
      label: semanticsLabel,
      child: tile,
    );
  }
}
