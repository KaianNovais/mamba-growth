import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final repo = context.watch<AuthRepository>();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            tooltip: l10n.homeSignOut,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => repo.signOut(),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: EmptyFeatureState(
          icon: Icons.cottage_outlined,
          eyebrow: l10n.navHome,
          title: l10n.homeEmptyTitle,
          subtitle: l10n.homeEmptySubtitle,
        ),
      ),
    );
  }
}
