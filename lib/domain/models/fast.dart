import 'package:flutter/foundation.dart';

@immutable
class Fast {
  const Fast({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.targetHours,
    required this.eatingHours,
    required this.completed,
  });

  final int id;
  final DateTime startAt;
  final DateTime? endAt;
  final int targetHours;
  final int eatingHours;
  final bool completed;

  bool get isActive => endAt == null;

  Duration get target => Duration(hours: targetHours);

  Duration elapsed(DateTime now) {
    final e = now.difference(startAt);
    return e.isNegative ? Duration.zero : e;
  }

  Duration remaining(DateTime now) {
    final r = target - elapsed(now);
    return r.isNegative ? Duration.zero : r;
  }

  double progress(DateTime now) {
    if (target.inSeconds == 0) return 0;
    return (elapsed(now).inSeconds / target.inSeconds).clamp(0.0, 1.0);
  }

  DateTime get plannedEndAt => startAt.add(target);

  bool overshot(DateTime now) => now.isAfter(plannedEndAt);
}
