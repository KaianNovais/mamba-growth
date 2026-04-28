import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.navStats)),
      body: SafeArea(
        top: false,
        child: EmptyFeatureState(
          icon: Icons.insights_outlined,
          eyebrow: l10n.navStats,
          title: l10n.statsEmptyTitle,
          subtitle: l10n.statsEmptySubtitle,
        ),
      ),
    );
  }
}
