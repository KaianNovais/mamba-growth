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

  /// Label legível usado em UI (pill da AppBar, cards do sheet).
  String get displayLabel => '$fastingHours:$eatingHours';

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
