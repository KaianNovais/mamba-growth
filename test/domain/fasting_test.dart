import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/domain/models/fast.dart';
import 'package:mamba_growth/domain/models/fasting_protocol.dart';

void main() {
  group('FastingProtocol', () {
    test('default é 16:8', () {
      expect(FastingProtocol.defaultProtocol.id, '16:8');
      expect(FastingProtocol.defaultProtocol.fastingHours, 16);
      expect(FastingProtocol.defaultProtocol.eatingHours, 8);
      expect(FastingProtocol.defaultProtocol.isCustom, false);
    });

    test('todos os presets somam 24h', () {
      for (final p in FastingProtocol.presets) {
        expect(p.fastingHours + p.eatingHours, 24,
            reason: 'preset ${p.id} não soma 24');
      }
    });

    test('custom factory monta id "custom:F:E"', () {
      final p = FastingProtocol.custom(fastingHours: 20, eatingHours: 4);
      expect(p.id, 'custom:20:4');
      expect(p.isCustom, true);
    });

    test('parseId reconhece preset e custom', () {
      expect(FastingProtocol.parseId('16:8'), FastingProtocol.presets[1]);
      final c = FastingProtocol.parseId('custom:20:4');
      expect(c.isCustom, true);
      expect(c.fastingHours, 20);
      expect(c.eatingHours, 4);
    });
  });

  group('Fast', () {
    final start = DateTime.utc(2026, 1, 1, 8);
    final active = Fast(
      id: 1,
      startAt: start,
      endAt: null,
      targetHours: 16,
      eatingHours: 8,
      completed: false,
    );

    test('isActive segue endAt', () {
      expect(active.isActive, true);
      final ended = Fast(
        id: 1,
        startAt: start,
        endAt: start.add(const Duration(hours: 16)),
        targetHours: 16,
        eatingHours: 8,
        completed: true,
      );
      expect(ended.isActive, false);
    });

    test('elapsed cresce com o tempo', () {
      final now = start.add(const Duration(hours: 4));
      expect(active.elapsed(now), const Duration(hours: 4));
    });

    test('remaining é zero depois da meta', () {
      final now = start.add(const Duration(hours: 20));
      expect(active.remaining(now), Duration.zero);
    });

    test('progress fica entre 0 e 1', () {
      expect(active.progress(start), 0.0);
      expect(active.progress(start.add(const Duration(hours: 8))), 0.5);
      expect(active.progress(start.add(const Duration(hours: 50))), 1.0);
    });
  });
}
