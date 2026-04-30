import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.navHome)),
      body: SafeArea(
        top: false,
        child: EmptyFeatureState(
          icon: Icons.home_rounded,
          eyebrow: l10n.navHome,
          title: l10n.homeNewEmptyTitle,
          subtitle: l10n.homeNewEmptySubtitle,
        ),
      ),
    );
  }
}
