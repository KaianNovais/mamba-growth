import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/meals/meals_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/settings_group.dart';
import '../../core/widgets/settings_tile.dart';
import '../../history/widgets/history_screen.dart';
import '../../meals_history/widgets/meals_history_screen.dart';
import 'app_version_label.dart';
import 'calorie_goal_sheet.dart';
import 'profile_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          children: const [
            ProfileHeader(),
            SizedBox(height: AppSpacing.xl),
            _GoalsAndTrackingGroup(),
            SizedBox(height: AppSpacing.xl),
            _PreferencesGroup(),
            SizedBox(height: AppSpacing.xl),
            _AboutGroup(),
            SizedBox(height: AppSpacing.xl),
            _SignOutGroup(),
            SizedBox(height: AppSpacing.xl),
            AppVersionLabel(),
          ],
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  HapticFeedback.selectionClick();
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.profileComingSoonSnack),
        duration: const Duration(seconds: 2),
      ),
    );
}

class _GoalsAndTrackingGroup extends StatelessWidget {
  const _GoalsAndTrackingGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goal = context.watch<MealsRepository>().currentGoal;

    return SettingsGroup(
      title: l10n.profileGroupGoalsTitle,
      children: [
        SettingsTile(
          icon: Icons.flag_outlined,
          title: l10n.profileGoalRowTitle,
          subtitle: goal == null ? l10n.profileGoalRowEmptySubtitle : null,
          trailingText:
              goal != null ? l10n.profileGoalRowValue(goal) : null,
          onTap: () => CalorieGoalSheet.show(context),
        ),
        SettingsTile(
          icon: Icons.local_fire_department_outlined,
          title: l10n.profileHistoryRowTitle,
          subtitle: l10n.profileHistoryRowSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const HistoryScreen(),
            ),
          ),
        ),
        SettingsTile(
          icon: Icons.restaurant_outlined,
          title: l10n.profileMealsHistoryRowTitle,
          subtitle: l10n.profileMealsHistoryRowSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MealsHistoryScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreferencesGroup extends StatelessWidget {
  const _PreferencesGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SettingsGroup(
      title: l10n.profileGroupPreferencesTitle,
      children: [
        SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: l10n.profileRowAppearance,
          trailingText: l10n.profileRowAppearanceValueDark,
          onTap: () => _showComingSoon(context),
        ),
        SettingsTile(
          icon: Icons.notifications_outlined,
          title: l10n.profileRowNotifications,
          onTap: () => _showComingSoon(context),
        ),
        SettingsTile(
          icon: Icons.language_outlined,
          title: l10n.profileRowLanguage,
          trailingText: l10n.profileRowLanguageValueAuto,
          onTap: () => _showComingSoon(context),
        ),
        SettingsTile(
          icon: Icons.straighten_outlined,
          title: l10n.profileRowUnits,
          trailingText: l10n.profileRowUnitsValue,
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }
}

class _AboutGroup extends StatelessWidget {
  const _AboutGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SettingsGroup(
      title: l10n.profileGroupAboutTitle,
      children: [
        SettingsTile(
          icon: Icons.help_outline_rounded,
          title: l10n.profileRowSupport,
          onTap: () => _showComingSoon(context),
        ),
        SettingsTile(
          icon: Icons.shield_outlined,
          title: l10n.profileRowPrivacy,
          onTap: () => _showComingSoon(context),
        ),
        SettingsTile(
          icon: Icons.description_outlined,
          title: l10n.profileRowTerms,
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }
}

class _SignOutGroup extends StatelessWidget {
  const _SignOutGroup();

  Future<void> _confirmSignOut(BuildContext context) async {
    HapticFeedback.selectionClick();
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final repo = context.read<AuthRepository>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(l10n.profileSignOutDialogTitle),
          content: Text(l10n.profileSignOutDialogBody),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10n.profileSignOutDialogCancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colors.danger),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l10n.profileSignOutDialogConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await repo.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SettingsGroup(
      children: [
        SettingsTile(
          icon: Icons.logout_rounded,
          title: l10n.profileSignOut,
          destructive: true,
          showChevron: false,
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }
}
