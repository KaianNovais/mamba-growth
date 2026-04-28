import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/brand_mark.dart';

/// Tela de boot, exibida enquanto o `AuthRepository` ainda não recebeu
/// o primeiro evento de `authStateChanges`. Praticamente instantânea
/// em sessões persistidas.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(label: l10n.appName),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
