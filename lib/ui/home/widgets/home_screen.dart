import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../domain/models/fast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../utils/result.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/progress_ring.dart';
import '../view_models/home_view_model.dart';
import 'end_fast_dialog.dart';
import 'fast_completed_sheet.dart';
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

class _Body extends StatefulWidget {
  const _Body({required this.vm});
  final HomeViewModel vm;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final Listenable _commands;

  @override
  void initState() {
    super.initState();
    _commands = Listenable.merge([widget.vm.startFast, widget.vm.endFast]);
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  Future<void> _onPrimaryPressed(BuildContext context) async {
    final vm = widget.vm;
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

    // Jejum atingiu a meta → encerra direto e celebra. Sem dialog de
    // confirmação porque não há nada a "desfazer": o usuário cumpriu.
    if (fast.overshot(vm.now) || fast.progress(vm.now) >= 1.0) {
      HapticFeedback.lightImpact();
      final elapsed = fast.elapsed(vm.now);
      await vm.endFast.execute();
      if (vm.endFast.completed && context.mounted) {
        await FastCompletedSheet.show(context, duration: elapsed);
      }
      return;
    }

    // Encerramento antecipado → dialog de freio com hierarquia invertida.
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
    final vm = widget.vm;
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final fast = vm.activeFast;
    final protocol = vm.selectedProtocol;
    final ringDiameter =
        (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 280.0);

    final eyebrow = fast != null
        ? '${l10n.homeProtocolEyebrow} · ${protocol.displayLabel}'
        : '${l10n.homeNextProtocolEyebrow} · ${protocol.displayLabel}';

    final idleCenterText =
        protocol.isTestProtocol ? '2min' : '${protocol.fastingHours}h';

    // Ring + semantics + center child: dinâmico quando há jejum ativo
    // (depende de `now`), estático quando não há.
    final Widget ringWidget = fast != null
        ? ValueListenableBuilder<DateTime>(
            valueListenable: vm.nowListenable,
            builder: (context, now, _) {
              final elapsed = fast.elapsed(now);
              final remaining = fast.remaining(now);
              return Semantics(
                button: false,
                label: l10n.homeRingSemanticsActive(
                  elapsed.inHours,
                  elapsed.inMinutes % 60,
                  remaining.inHours,
                  remaining.inMinutes % 60,
                  fast.targetHours,
                ),
                child: ProgressRing(
                  progress: fast.progress(now),
                  size: ringDiameter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatElapsed(elapsed),
                        style: typo.numericLarge.copyWith(color: colors.accent),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.homeElapsedLabel,
                        style: typo.caption
                            .copyWith(color: colors.textDim, letterSpacing: 1.6),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        : Semantics(
            button: true,
            label: l10n.homeRingSemanticsIdle(protocol.fastingHours),
            child: ProgressRing(
              progress: 0,
              size: ringDiameter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    idleCenterText,
                    style: typo.numericLarge.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.homeFastingTargetLabel,
                    style: typo.caption
                        .copyWith(color: colors.textDim, letterSpacing: 1.6),
                  ),
                ],
              ),
            ),
          );

    final Widget subtitle = fast != null
        ? ValueListenableBuilder<DateTime>(
            valueListenable: vm.nowListenable,
            builder: (_, now, _) => _ActiveSubtitle(fast: fast, now: now),
          )
        : protocol.isTestProtocol
            ? Text(
                'Modo de teste · 2 minutos',
                style: text.bodyMedium?.copyWith(color: colors.textDim),
                textAlign: TextAlign.center,
              )
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: fast == null
                ? () {
                    HapticFeedback.selectionClick();
                    ProtocolBottomSheet.show(context);
                  }
                : null,
            child: ringWidget,
          ),
          const SizedBox(height: AppSpacing.xl),
          subtitle,
          const Spacer(),
          AnimatedBuilder(
            animation: _commands,
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
    final label = protocol.displayLabel;

    return Tooltip(
      message: l10n.homeProtocolAction,
      child: OutlinedButton.icon(
        onPressed: () => ProtocolBottomSheet.show(context),
        icon: const Icon(Icons.tune_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.border),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

