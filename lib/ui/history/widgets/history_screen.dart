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
  late final DateTime _today;
  late final DateTime _weekStart;
  late final List<DateTime> _weekDays;
  late final Future<Map<DateTime, List<Fast>>> _future;
  late DateTime _selectedDay;

  // DateFormat é caro de instanciar e o locale só muda raramente.
  // Cacheamos por locale e recalculamos em didChangeDependencies.
  String? _cachedLocale;
  late DateFormat _timeFormat;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _weekStart = WeekDaySelector.startOfWeekSunday(_today);
    _weekDays = WeekDaySelector.currentWeekDays(_today);
    _selectedDay = _today;

    // Janela limitada: só puxamos jejuns da semana exibida.
    // Antes: watchCompletedFasts() carregava TODO o histórico em memória
    // e a tela filtrava em O(n) a cada troca de dia.
    final repo = context.read<FastingRepository>();
    final end = _weekStart.add(const Duration(days: 7));
    _future = repo.getFastsBetween(_weekStart, end).then(_groupByEndDay);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_cachedLocale != locale) {
      _cachedLocale = locale;
      _timeFormat = DateFormat.Hm(locale);
    }
  }

  Map<DateTime, List<Fast>> _groupByEndDay(List<Fast> fasts) {
    final byDay = <DateTime, List<Fast>>{};
    for (final f in fasts) {
      final end = f.endAt;
      if (end == null) continue;
      final day = DateTime(end.year, end.month, end.day);
      byDay.putIfAbsent(day, () => []).add(f);
    }
    return byDay;
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            children: [
              // Selector vive fora do FutureBuilder: completar o future
              // (ou re-render do snapshot) não rebuilda os 7 círculos.
              RepaintBoundary(
                child: WeekDaySelector(
                  weekDays: _weekDays,
                  today: _today,
                  selectedDay: _selectedDay,
                  onSelect: (day) => setState(() => _selectedDay = day),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: FutureBuilder<Map<DateTime, List<Fast>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final byDay = snapshot.data!;
                    final dayFasts = byDay[_selectedDay] ?? const <Fast>[];

                    if (dayFasts.isEmpty) {
                      return _EmptyDay(message: l10n.historyDayEmpty);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      itemCount: dayFasts.length,
                      itemBuilder: (ctx, i) {
                        final fast = dayFasts[i];
                        return Padding(
                          key: ValueKey(fast.id),
                          padding: EdgeInsets.only(
                            top: i == 0 ? 0 : AppSpacing.md,
                          ),
                          child: _HistoryItem(
                            fast: fast,
                            timeFormat: _timeFormat,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
  const _HistoryItem({required this.fast, required this.timeFormat});

  final Fast fast;
  final DateFormat timeFormat;

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
                  timeFormat.format(endAt),
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
