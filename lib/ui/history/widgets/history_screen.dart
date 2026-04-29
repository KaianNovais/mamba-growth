import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../domain/models/fast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Stream<List<Fast>> _stream;

  @override
  void initState() {
    super.initState();
    // Cacheado uma vez: watchCompletedFasts() é `async*` e cria uma
    // nova stream a cada chamada — invocá-la dentro de build forçaria
    // re-subscribe a cada rebuild. context.read também evita
    // rebuildar a tela em qualquer notify do repo (start/end/protocolo);
    // a stream já cobre o que essa tela precisa.
    _stream = context.read<FastingRepository>().watchCompletedFasts();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.navHistory)),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Fast>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final fasts = snapshot.data!;
            if (fasts.isEmpty) {
              return EmptyFeatureState(
                icon: Icons.history_rounded,
                eyebrow: l10n.navHistory,
                title: l10n.historyEmptyTitle,
                subtitle: l10n.historyEmptySubtitle,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              itemCount: fasts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _HistoryItem(fast: fasts[i]),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.fast});

  final Fast fast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);

    final endAt = fast.endAt!;
    final elapsed = endAt.difference(fast.startAt);
    final isTest = fast.targetHours == 0;
    final targetLabel =
        isTest ? l10n.historyItemTestProtocol : '${fast.targetHours}h';
    final summary = l10n.historyItemSummary(
      _formatElapsed(elapsed),
      targetLabel,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatHeader(context, endAt),
                  style: typo.caption.copyWith(
                    color: colors.textDim,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _StatusPill(completed: fast.completed),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            summary,
            style: text.titleLarge?.copyWith(color: colors.text),
          ),
        ],
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0) return '${m}min';
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  String _formatHeader(BuildContext context, DateTime endAt) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(endAt.year, endAt.month, endAt.day);
    final delta = today.difference(endDate).inDays;

    final time = DateFormat.Hm(locale).format(endAt);

    final dayLabel = switch (delta) {
      0 => l10n.historyDateToday,
      1 => l10n.historyDateYesterday,
      _ => DateFormat('d MMM', locale).format(endAt),
    };

    return '${dayLabel.toUpperCase()} · $time';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);

    final color = completed ? colors.accent : colors.textDimmer;
    final label = completed
        ? l10n.historyItemStatusCompleted
        : l10n.historyItemStatusEarly;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_rounded : Icons.stop_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: typo.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
