import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.navHistory)),
      body: SafeArea(
        top: false,
        child: EmptyFeatureState(
          icon: Icons.history_rounded,
          eyebrow: l10n.navHistory,
          title: l10n.historyEmptyTitle,
          subtitle: l10n.historyEmptySubtitle,
        ),
      ),
    );
  }
}
