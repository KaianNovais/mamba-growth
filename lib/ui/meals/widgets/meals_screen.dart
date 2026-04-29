import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.navMeals)),
      body: SafeArea(
        top: false,
        child: EmptyFeatureState(
          icon: Icons.restaurant_outlined,
          eyebrow: l10n.navMeals,
          title: l10n.mealsEmptyTitle,
          subtitle: l10n.mealsEmptySubtitle,
        ),
      ),
    );
  }
}
