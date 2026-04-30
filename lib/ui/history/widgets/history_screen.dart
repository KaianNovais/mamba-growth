import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../domain/models/fast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/week_day_selector.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Stream<List<Fast>> _stream;
  late final DateTime _today;
  late final List<DateTime> _weekDays;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _weekDays = WeekDaySelector.currentWeekDays(_today);
    _selectedDay = _today;

    // Cacheado uma vez: watchCompletedFasts() é `async*` e cria uma
    // nova stream a cada chamada — invocá-la dentro de build forçaria
    // re-subscribe a cada rebuild. context.read também evita
    // rebuildar a tela em qualquer notify do repo (start/end/protocolo);
    // a stream já cobre o que essa tela precisa.
    _stream = context.read<FastingRepository>().watchCompletedFasts();
  }

  bool _endedOn(Fast fast, DateTime day) {
    final end = fast.endAt;
    if (end == null) return false;
    final endDay = DateTime(end.year, end.month, end.day);
    return endDay.isAtSameMomentAs(day);
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
            final dayFasts =
                fasts.where((f) => _endedOn(f, _selectedDay)).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                WeekDaySelector(
                  weekDays: _weekDays,
                  today: _today,
                  selectedDay: _selectedDay,
                  onSelect: (day) => setState(() => _selectedDay = day),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (dayFasts.isEmpty)
                  _EmptyDay(message: l10n.historyDayEmpty)
                else
                  for (var i = 0; i < dayFasts.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    _HistoryItem(fast: dayFasts[i]),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: colors.textDim),
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
                  _formatTimeHeader(context, endAt),
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

  String _formatTimeHeader(BuildContext context, DateTime endAt) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.Hm(locale).format(endAt);
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
