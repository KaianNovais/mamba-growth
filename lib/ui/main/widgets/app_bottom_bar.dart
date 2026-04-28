import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/themes/themes.dart';

class AppBottomBarItem {
  const AppBottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final List<AppBottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(
          top: BorderSide(color: colors.borderDim, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BottomBarTab(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onItemSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarTab extends StatelessWidget {
  const _BottomBarTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final color = selected ? colors.accent : colors.textDim;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.surface2 : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: typo.caption.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.4,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
