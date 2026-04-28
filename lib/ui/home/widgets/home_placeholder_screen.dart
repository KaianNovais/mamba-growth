import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

/// Placeholder pós-login. Será substituído pela home real.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final repo = context.watch<AuthRepository>();
    final user = repo.currentUser;
    final name = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email ?? '');

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.appName),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.homeWelcomeGreeting(name),
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.homeComingSoon,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: colors.textDim),
              ),
              const SizedBox(height: AppSpacing.xl2),
              OutlinedButton.icon(
                onPressed: () async {
                  await repo.signOut();
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.homeSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
