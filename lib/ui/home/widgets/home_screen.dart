import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../domain/models/auth_user.dart';
import '../../../domain/models/fast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../../utils/result.dart';
import '../../core/themes/themes.dart';
import '../view_models/home_view_model.dart';
import 'end_fast_dialog.dart';
import 'fasting_ring.dart';
import 'protocol_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (ctx) => HomeViewModel(
        repository: ctx.read<FastingRepository>(),
      ),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.homeFastingTitle),
        actions: const [
          _ProtocolAction(),
          SizedBox(width: AppSpacing.sm),
          _UserAvatarAction(),
          SizedBox(width: AppSpacing.lg),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Consumer<HomeViewModel>(
          builder: (context, vm, _) {
            if (!vm.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return _Body(vm: vm);
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vm});
  final HomeViewModel vm;

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  Future<void> _onPrimaryPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final fast = vm.activeFast;

    if (fast == null) {
      HapticFeedback.lightImpact();
      await vm.startFast.execute();
      final result = vm.startFast.result;
      if (result is Error<Fast>) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.authErrorUnknown)),
        );
      }
      return;
    }

    final confirmed = await EndFastDialog.show(
      context,
      fast: fast,
      now: vm.now,
    );
    if (!confirmed) return;
    await vm.endFast.execute();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final fast = vm.activeFast;
    final protocol = vm.selectedProtocol;
    final ringDiameter =
        (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 280.0);

    final eyebrow = fast != null
        ? '${l10n.homeProtocolEyebrow} · ${protocol.fastingHours}:${protocol.eatingHours}'
        : '${l10n.homeNextProtocolEyebrow} · ${protocol.fastingHours}:${protocol.eatingHours}';

    final progress = fast?.progress(vm.now) ?? 0.0;

    final centerChild = fast != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatElapsed(fast.elapsed(vm.now)),
                style: typo.numericLarge.copyWith(color: colors.accent),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeElapsedLabel,
                style: typo.caption.copyWith(color: colors.textDim, letterSpacing: 1.6),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${protocol.fastingHours}h',
                style: typo.numericLarge.copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeFastingTargetLabel,
                style: typo.caption.copyWith(color: colors.textDim, letterSpacing: 1.6),
              ),
            ],
          );

    final subtitle = fast != null
        ? _ActiveSubtitle(fast: fast, now: vm.now)
        : Text(
            l10n.homeEatingWindow(protocol.eatingHours),
            style: text.bodyMedium?.copyWith(color: colors.textDim),
            textAlign: TextAlign.center,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const Spacer(),
          Text(
            eyebrow.toUpperCase(),
            style: typo.caption.copyWith(
              color: colors.textDim,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            label: fast != null
                ? l10n.homeRingSemanticsActive(
                    fast.elapsed(vm.now).inHours,
                    fast.elapsed(vm.now).inMinutes % 60,
                    fast.remaining(vm.now).inHours,
                    fast.remaining(vm.now).inMinutes % 60,
                    fast.targetHours,
                  )
                : l10n.homeRingSemanticsIdle(protocol.fastingHours),
            child: FastingRing(
              progress: progress,
              size: ringDiameter,
              child: centerChild,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          subtitle,
          const Spacer(),
          AnimatedBuilder(
            animation: Listenable.merge([vm.startFast, vm.endFast]),
            builder: (context, _) {
              final running = vm.startFast.running || vm.endFast.running;
              final isActive = vm.activeFast != null;
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: running ? null : () => _onPrimaryPressed(context),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isActive ? colors.surface2 : colors.accent,
                    foregroundColor: isActive ? colors.text : colors.bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: running
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              isActive ? colors.text : colors.bg,
                            ),
                          ),
                        )
                      : Text(
                          isActive ? l10n.homeEndFast : l10n.homeStartFast,
                          style: text.labelLarge?.copyWith(
                            color: isActive ? colors.text : colors.bg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ActiveSubtitle extends StatelessWidget {
  const _ActiveSubtitle({required this.fast, required this.now});
  final Fast fast;
  final DateTime now;

  String _formatRemaining(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0) return '${m}min';
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  String _formatClock(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    if (fast.overshot(now)) {
      final over = now.difference(fast.plannedEndAt);
      return Column(
        children: [
          Text(
            l10n.homeGoalReached,
            style: text.bodyLarge?.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.homeGoalReachedAgo(_formatRemaining(over)),
            style: text.bodyMedium?.copyWith(color: colors.textDim),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          l10n.homeEndsIn(_formatRemaining(fast.remaining(now))),
          style: text.bodyLarge?.copyWith(color: colors.text),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.homeEndsAt(_formatClock(fast.plannedEndAt)),
          style: text.bodyMedium?.copyWith(color: colors.textDim),
        ),
      ],
    );
  }
}

class _ProtocolAction extends StatelessWidget {
  const _ProtocolAction();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final protocol = context.watch<FastingRepository>().selectedProtocol;
    final label = '${protocol.fastingHours}:${protocol.eatingHours}';

    return Tooltip(
      message: l10n.homeProtocolAction,
      child: OutlinedButton(
        onPressed: () => ProtocolBottomSheet.show(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.border),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          textStyle: text.labelMedium,
        ),
        child: Text(label),
      ),
    );
  }
}

class _UserAvatarAction extends StatelessWidget {
  const _UserAvatarAction();

  static const _size = 36.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthRepository>().currentUser;
    final photo = user?.photoUrl;
    final initials = _initialsFor(user);

    return Tooltip(
      message: l10n.homeProfileAction,
      child: InkWell(
        onTap: () => context.pushNamed(RouteNames.profile),
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: _size / 2,
          backgroundColor: colors.surface2,
          foregroundImage: (photo != null && photo.isNotEmpty)
              ? NetworkImage(photo)
              : null,
          child: Text(
            initials,
            style: text.labelMedium?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  static String _initialsFor(AuthUser? user) {
    if (user == null) return '?';
    final name = (user.displayName ?? '').trim();
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length == 1) return parts.first[0].toUpperCase();
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    final email = user.email.trim();
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
}
