import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/ui/home/state/aggregations.dart';

void main() {
  group('startOfDay', () {
    test('strips time-of-day', () {
      final d = DateTime(2026, 4, 30, 13, 45, 12);
      expect(startOfDay(d), DateTime(2026, 4, 30));
    });
  });

  group('startOfWeekSunday', () {
    test('Sunday returns same Sunday at 00:00', () {
      final d = DateTime(2026, 4, 26, 22, 10); // Sunday
      expect(startOfWeekSunday(d), DateTime(2026, 4, 26));
    });

    test('Wednesday returns previous Sunday at 00:00', () {
      final d = DateTime(2026, 4, 29, 9); // Wednesday
      expect(startOfWeekSunday(d), DateTime(2026, 4, 26));
    });

    test('Saturday returns Sunday 6 days back', () {
      final d = DateTime(2026, 5, 2, 23, 59); // Saturday
      expect(startOfWeekSunday(d), DateTime(2026, 4, 26));
    });
  });

  group('currentWeekDays', () {
    test('returns 7 sequential days dom→sáb at 00:00', () {
      final week = currentWeekDays(DateTime(2026, 4, 29));
      expect(week, [
        DateTime(2026, 4, 26),
        DateTime(2026, 4, 27),
        DateTime(2026, 4, 28),
        DateTime(2026, 4, 29),
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 2),
      ]);
    });
  });
}
