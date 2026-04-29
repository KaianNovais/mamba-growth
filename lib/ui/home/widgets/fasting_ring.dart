import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/themes/themes.dart';

/// Anel circular que representa o progresso do jejum.
///
/// Inspirado no waveform do Material 3 expressive — o arco ativo é
/// perturbado por uma seno com fase animando devagar (4s/loop). A
/// amplitude faz tapering nas pontas (sin(πt)) pra que o stroke cap
/// arredondado se feche limpo. Quando `progress == 0` a fase para de
/// animar pra não desperdiçar frames.
///
/// API externa idêntica à versão anterior.
class FastingRing extends StatefulWidget {
  const FastingRing({
    super.key,
    required this.progress,
    required this.size,
    required this.child,
  });

  final double progress;
  final double size;
  final Widget child;

  @override
  State<FastingRing> createState() => _FastingRingState();
}

class _FastingRingState extends State<FastingRing>
    with TickerProviderStateMixin {
  static const _phaseDuration = Duration(seconds: 4);
  static const _progressDuration = Duration(milliseconds: 320);
  // Acima desse delta animamos com tween (mudanças "humanamente
  // perceptíveis" — start/end fast, troca de protocolo). Abaixo, só
  // snapshotamos pra evitar re-disparar a animação de 320ms a cada
  // tick 1Hz quando o progresso avança ~0,00002/s num jejum de 16h.
  static const _animateDeltaThreshold = 0.01;

  late final AnimationController _phaseCtrl;
  late final AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    final initial = widget.progress.clamp(0.0, 1.0);
    _phaseCtrl = AnimationController(vsync: this, duration: _phaseDuration);
    _progressCtrl =
        AnimationController(vsync: this, duration: _progressDuration);
    _progressAnim = AlwaysStoppedAnimation(initial);
    if (initial > 0) _phaseCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant FastingRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.progress.clamp(0.0, 1.0);
    final current = _progressAnim.value;
    final delta = (next - current).abs();
    if (delta > _animateDeltaThreshold) {
      _progressAnim = Tween<double>(begin: current, end: next).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
      );
      _progressCtrl.forward(from: 0);
    } else if (delta > 0) {
      // Snap silencioso. O painter usa _progressAnim.value, e o
      // _phaseCtrl em loop garante que a próxima frame leia o valor
      // novo (~16ms depois) — imperceptível.
      _progressAnim = AlwaysStoppedAnimation(next);
    }
    if (next > 0 && !_phaseCtrl.isAnimating) {
      _phaseCtrl.repeat();
    } else if (next <= 0 && _phaseCtrl.isAnimating) {
      _phaseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _phaseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_phaseCtrl, _progressCtrl]),
          builder: (context, _) => CustomPaint(
            painter: _WavyRingPainter(
              progress: _progressAnim.value,
              phase: _phaseCtrl.value * 2 * math.pi,
              trackColor: colors.borderDim,
              progressColor: colors.accent,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _WavyRingPainter extends CustomPainter {
  _WavyRingPainter({
    required this.progress,
    required this.phase,
    required this.trackColor,
    required this.progressColor,
  });

  static const _strokeWidth = 6.0;
  static const _amplitude = 2.8;
  static const _wavelengthDp = 36.0;

  final double progress;
  final double phase;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Reservamos espaço para a amplitude de cada lado da circunferência
    // — assim a onda nunca "vaza" do widget.
    final radius =
        (math.min(size.width, size.height) - _strokeWidth - _amplitude * 2) /
            2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    final arcLength = sweep * radius;
    // Pelo menos uma onda inteira; arredondamos para int para evitar
    // que a senóide quebre no meio do ciclo.
    final waveCount = math.max(1, (arcLength / _wavelengthDp).round());

    // ~8 segmentos por onda dá curva visualmente suave.
    final segments = math.max(60, waveCount * 8);

    final path = Path();
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final theta = start + sweep * t;
      // sin(πt) leva amplitude a 0 nas duas pontas — o stroke cap
      // arredondado se fecha sem ressalto.
      final taper = math.sin(t * math.pi);
      final amp = _amplitude * taper;
      final r = radius + amp * math.sin(t * waveCount * 2 * math.pi + phase);
      final dx = center.dx + r * math.cos(theta);
      final dy = center.dy + r * math.sin(theta);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final fgPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _WavyRingPainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
