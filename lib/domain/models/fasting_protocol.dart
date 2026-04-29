import 'package:flutter/foundation.dart';

@immutable
class FastingProtocol {
  const FastingProtocol({
    required this.id,
    required this.fastingHours,
    required this.eatingHours,
    required this.isCustom,
  });

  final String id;
  final int fastingHours;
  final int eatingHours;
  final bool isCustom;

  static const _p168 = FastingProtocol(id: '16:8', fastingHours: 16, eatingHours: 8, isCustom: false);

  static const presets = <FastingProtocol>[
    FastingProtocol(id: '12:12', fastingHours: 12, eatingHours: 12, isCustom: false),
    _p168,
    FastingProtocol(id: '18:6',  fastingHours: 18, eatingHours:  6, isCustom: false),
  ];

  static const defaultProtocol = _p168; // 16:8

  // TODO(remove): Protocolo de teste de 2 minutos para validação manual
  // do timer + notificação. Remover (e a special-case em Fast.target,
  // o tile no ProtocolBottomSheet e o branch em displayLabel) ao
  // final dos smoke tests.
  static const testTwoMinutes = FastingProtocol(
    id: 'test:2min',
    fastingHours: 0,
    eatingHours: 0,
    isCustom: false,
  );

  bool get isTestProtocol => id == testTwoMinutes.id;

  /// Label legível usado em UI (pill da AppBar, cards do sheet).
  /// Para o protocolo de teste retorna "2min"; caso contrário, "X:Y".
  String get displayLabel =>
      isTestProtocol ? '2min' : '$fastingHours:$eatingHours';

  factory FastingProtocol.custom({
    required int fastingHours,
    required int eatingHours,
  }) {
    assert(fastingHours + eatingHours == 24);
    return FastingProtocol(
      id: 'custom:$fastingHours:$eatingHours',
      fastingHours: fastingHours,
      eatingHours: eatingHours,
      isCustom: true,
    );
  }

  factory FastingProtocol.parseId(String id) {
    if (id == testTwoMinutes.id) return testTwoMinutes;
    for (final p in presets) {
      if (p.id == id) return p;
    }
    if (id.startsWith('custom:')) {
      final parts = id.split(':');
      if (parts.length == 3) {
        final f = int.tryParse(parts[1]);
        final e = int.tryParse(parts[2]);
        if (f != null && e != null && f + e == 24 && f > 0 && f < 24) {
          return FastingProtocol.custom(fastingHours: f, eatingHours: e);
        }
      }
    }
    return defaultProtocol;
  }

  @override
  bool operator ==(Object other) =>
      other is FastingProtocol && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
