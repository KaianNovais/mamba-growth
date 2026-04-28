import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import 'fasting_clock.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.onContinue,
  });

  final VoidCallback? onContinue;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _orbFade;
  late final Animation<double> _orbScale;
  late final Animation<double> _eyebrowFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _pillarsFade;
  late final Animation<double> _ctaFade;
  late final Animation<Offset> _ctaSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _orbFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _orbScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _eyebrowFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
    );
    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.90, curve: Curves.easeOut),
    );
    _pillarsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
    );
    _ctaFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );
    _ctaSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typo = context.typo;
    final text = context.text;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: colors.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            const _AmbientGlow(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.lg),
                              _BrandMark(label: l10n.appName),
                              const Spacer(flex: 2),
                              Center(
                                child: FadeTransition(
                                  opacity: _orbFade,
                                  child: ScaleTransition(
                                    scale: _orbScale,
                                    child: RepaintBoundary(
                                      child: FastingClock(
                                        size: 220,
                                        fastingProgress: 10.4 / 16,
                                        calorieProgress: 1247 / 1800,
                                        timeLabel: '10:24',
                                        caption: l10n.onboardingHeroLabel,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FadeTransition(
                                opacity: _orbFade,
                                child: Text(
                                  l10n.onboardingHeroFootnote,
                                  textAlign: TextAlign.center,
                                  style: typo.caption.copyWith(
                                    color: colors.textDimmer,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl2),
                              FadeTransition(
                                opacity: _eyebrowFade,
                                child: Text(
                                  l10n.onboardingEyebrow,
                                  textAlign: TextAlign.center,
                                  style: typo.caption.copyWith(
                                    color: colors.accent,
                                    letterSpacing: 2.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FadeTransition(
                                opacity: _titleFade,
                                child: Text(
                                  l10n.onboardingTitle,
                                  textAlign: TextAlign.center,
                                  style: text.displaySmall?.copyWith(
                                    color: colors.text,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              FadeTransition(
                                opacity: _subtitleFade,
                                child: Text(
                                  l10n.onboardingSubtitle,
                                  textAlign: TextAlign.center,
                                  style: text.bodyLarge?.copyWith(
                                    color: colors.textDim,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                              const Spacer(flex: 2),
                              FadeTransition(
                                opacity: _pillarsFade,
                                child: _PillarsRow(
                                  labels: [
                                    l10n.onboardingPillarFocus,
                                    l10n.onboardingPillarDiscipline,
                                    l10n.onboardingPillarGrowth,
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: AppSpacing.xl2 + AppSpacing.xl3 + AppSpacing.md,
                              ),
                              FadeTransition(
                                opacity: _ctaFade,
                                child: SlideTransition(
                                  position: _ctaSlide,
                                  child: _PrimaryCta(
                                    label: l10n.onboardingPrimaryCta,
                                    onPressed: widget.onContinue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              FadeTransition(
                                opacity: _ctaFade,
                                child: Text.rich(
                                  TextSpan(
                                    children: _buildFooterSpans(
                                      template: l10n.onboardingFooter,
                                      emphasizedLabels: [
                                        l10n.onboardingFooterTermsLabel,
                                        l10n.onboardingFooterPrivacyLabel,
                                      ],
                                      emphasisStyle: TextStyle(
                                        color: colors.textDim,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                        decorationColor: colors.textDim,
                                      ),
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: text.bodySmall?.copyWith(
                                    color: colors.textDimmer,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<InlineSpan> _buildFooterSpans({
  required String template,
  required List<String> emphasizedLabels,
  required TextStyle emphasisStyle,
}) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  while (cursor < template.length) {
    var nextIndex = -1;
    var nextLabel = '';
    for (final label in emphasizedLabels) {
      if (label.isEmpty) continue;
      final found = template.indexOf(label, cursor);
      if (found >= 0 && (nextIndex < 0 || found < nextIndex)) {
        nextIndex = found;
        nextLabel = label;
      }
    }
    if (nextIndex < 0) {
      spans.add(TextSpan(text: template.substring(cursor)));
      break;
    }
    if (nextIndex > cursor) {
      spans.add(TextSpan(text: template.substring(cursor, nextIndex)));
    }
    spans.add(TextSpan(text: nextLabel, style: emphasisStyle));
    cursor = nextIndex + nextLabel.length;
  }
  return spans;
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.45),
              radius: 0.9,
              colors: [
                colors.accent.withValues(alpha: 0.10),
                colors.bg.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.accent,
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label.toUpperCase(),
          style: typo.caption.copyWith(
            color: colors.textDim,
            letterSpacing: 3.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PillarsRow extends StatelessWidget {
  const _PillarsRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  labels[i].toUpperCase(),
                  textAlign: TextAlign.center,
                  style: typo.caption.copyWith(
                    color: colors.textDim,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: text.labelLarge?.copyWith(
                color: colors.bg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.arrow_forward_rounded, size: 18, color: colors.bg),
          ],
        ),
      ),
    );
  }
}
